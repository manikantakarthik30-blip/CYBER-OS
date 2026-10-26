import json
import re
import uuid
from datetime import datetime, timezone
from typing import List, Dict, Any, Optional
import httpx

OSV_QUERYBATCH_URL = "https://api.osv.dev/v1/querybatch"

class DependencyScanner:
    def parse_pubspec(self, content: str) -> List[Dict[str, str]]:
        packages = []
        in_deps = False
        for line in content.splitlines():
            line_str = line.strip()
            if line_str in ('dependencies:', 'dev_dependencies:'):
                in_deps = True
                continue
            elif in_deps and line and not line.startswith(' ') and not line.startswith('\t'):
                in_deps = False

            if in_deps and ':' in line_str and not line_str.startswith('#'):
                parts = line_str.split(':', 1)
                pkg_name = parts[0].strip()
                version = parts[1].strip().replace('^', '').replace('"', '').replace("'", '').split(' ')[0]
                if version and re.match(r'^[0-9]', version):
                    packages.append({'name': pkg_name, 'version': version, 'ecosystem': 'Pub'})
        return packages

    def parse_package_json(self, content: str) -> List[Dict[str, str]]:
        packages = []
        try:
            data = json.loads(content)
            for section in ('dependencies', 'devDependencies'):
                deps = data.get(section, {})
                for pkg_name, ver_str in deps.items():
                    clean_ver = re.sub(r'[\^~>=<]', '', ver_str).strip()
                    if clean_ver and re.match(r'^[0-9]', clean_ver):
                        packages.append({'name': pkg_name, 'version': clean_ver, 'ecosystem': 'npm'})
        except Exception:
            pass
        return packages

    def parse_requirements_txt(self, content: str) -> List[Dict[str, str]]:
        packages = []
        for line in content.splitlines():
            line = line.strip()
            if line and not line.startswith('#'):
                match = re.match(r'^([a-zA-Z0-9_\-]+)\s*==\s*([0-9\.]+)', line)
                if match:
                    packages.append({'name': match.group(1), 'version': match.group(2), 'ecosystem': 'PyPI'})
        return packages

    async def scan_manifests(
        self,
        pubspec_content: Optional[str] = None,
        package_json_content: Optional[str] = None,
        requirements_content: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        queries = []
        if pubspec_content:
            queries.extend(self.parse_pubspec(pubspec_content))
        if package_json_content:
            queries.extend(self.parse_package_json(package_json_content))
        if requirements_content:
            queries.extend(self.parse_requirements_txt(requirements_content))

        if not queries:
            return []

        payload = {
            "queries": [
                {"package": {"name": q["name"], "ecosystem": q["ecosystem"]}, "version": q["version"]}
                for q in queries[:100]
            ]
        }

        vulnerabilities = []
        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                response = await client.post(OSV_QUERYBATCH_URL, json=payload)
                if response.status_code == 200:
                    results = response.json().get("results", [])
                    for idx, res in enumerate(results):
                        vulns = res.get("vulns", [])
                        pkg_info = queries[idx]
                        for v in vulns:
                            cve_id = v.get("id", "UNKNOWN-CVE")
                            details = v.get("details", "Known vulnerability reported in OSV database.")
                            summary = v.get("summary", details)

                            vulnerabilities.append({
                                'id': str(uuid.uuid4()),
                                'title': f'{cve_id} in {pkg_info["name"]} ({pkg_info["version"]})',
                                'severity': 'HIGH',
                                'category': 'Vulnerable Dependency',
                                'description': (summary[:200] + '...') if len(summary) > 200 else summary,
                                'location': f'manifest -> {pkg_info["name"]}=={pkg_info["version"]}',
                                'fix': f'Upgrade {pkg_info["name"]} to the latest patched version.',
                                'detectedAt': datetime.now(timezone.utc).isoformat()
                            })
        except Exception:
            pass

        return vulnerabilities
