from pathlib import Path
from collections import defaultdict, Counter
import hashlib, json, re
from difflib import SequenceMatcher

ROOT = Path(__file__).resolve().parents[1]
md_files = sorted(ROOT.glob("*.md"))
link_re = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
item_re = re.compile(
    r"- \[[ xX]\] \*\*(KIT-\d{2}-\d{2}) — (.*?)\*\*\n"
    r"  - \*\*Cách kiểm:\*\* (.*?)\n"
    r"  - \*\*Evidence mong đợi:\*\* (.*?)\n"
    r"  - \*\*Severity mặc định nếu không đạt:\*\* `(P[0-3])`\n",
    re.S,
)

broken_links=[]
ids=[]
blocks=[]
severities=[]
items=[]

for p in md_files:
    text=p.read_text(encoding="utf-8")
    for link in link_re.findall(text):
        if link.startswith(("http://","https://","#","mailto:")):
            continue
        target=(p.parent/link).resolve()
        if not target.exists():
            broken_links.append({"file":p.name,"link":link})
    for iid,check,method,evidence,severity in item_re.findall(text):
        ids.append(iid)
        severities.append(severity)
        norm=" ".join((check+" "+method+" "+evidence).lower().split())
        blocks.append((iid,norm,check.strip()))
        items.append({
            "id":iid,
            "check":check.strip(),
            "method":method.strip(),
            "evidence":evidence.strip(),
            "severity":severity,
        })

dup_ids=sorted({x for x in ids if ids.count(x)>1})

by_hash=defaultdict(list)
for iid,norm,check in blocks:
    by_hash[hashlib.sha256(norm.encode()).hexdigest()].append(iid)
exact=[v for v in by_hash.values() if len(v)>1]

near=[]
for i in range(len(blocks)):
    id1,_,c1=blocks[i]
    for j in range(i+1,len(blocks)):
        id2,_,c2=blocks[j]
        ratio=SequenceMatcher(None,c1.lower(),c2.lower()).ratio()
        if ratio>=0.90:
            near.append({
                "a":id1,"b":id2,"ratio":round(ratio,3),
                "text_a":c1,"text_b":c2
            })

kit_files=[p for p in md_files if re.match(r"KIT-\d{2}-[a-z0-9-]+\.md$",p.name)]
bad_slugs=[p.name for p in md_files if p.name.startswith("KIT-") and p not in kit_files]

severity_counts=dict(Counter(severities))
required_levels={"P0","P1","P2","P3"}
severity_levels_ok=required_levels.issubset(set(severity_counts))

# Calibration: accessible name, touch target, contrast không được thấp hơn P1.
critical_terms=("touch target","accessible name","contrast")
severity_rank={"P0":0,"P1":1,"P2":2,"P3":3}
calibration_warnings=[]
for item in items:
    haystack=(item["check"]+" "+item["method"]+" "+item["evidence"]).lower()
    matched=[term for term in critical_terms if term in haystack]
    if matched and severity_rank[item["severity"]]>severity_rank["P1"]:
        calibration_warnings.append({
            "id":item["id"],
            "severity":item["severity"],
            "matched_terms":matched,
            "check":item["check"],
        })

# Hybrid language detection:
# - Chỉ cảnh báo khi dòng có ký tự tiếng Việt có dấu.
# - Đồng thời xuất hiện liên từ/mạo từ tiếng Anh đứng độc lập.
# - Hoặc có từ có dấu tiếng Việt bị dính hậu tố "s".
vietnamese_diacritic_re = re.compile(
    r"[àáạảãâầấậẩẫăằắặẳẵ"
    r"èéẹẻẽêềếệểễ"
    r"ìíịỉĩ"
    r"òóọỏõôồốộổỗơờớợởỡ"
    r"ùúụủũưừứựửữ"
    r"ỳýỵỷỹđ]",
    re.IGNORECASE
)
english_connector_re = re.compile(
    r"\b(and|or|the|of|with|from|to|for|in|on|by|into|across|between)\b",
    re.IGNORECASE
)
broken_suffix_re = re.compile(
    r"\b[A-Za-zÀ-ỹ]*[àáạảãâầấậẩẫăằắặẳẵ"
    r"èéẹẻẽêềếệểễ"
    r"ìíịỉĩ"
    r"òóọỏõôồốộổỗơờớợởỡ"
    r"ùúụủũưừứựửữ"
    r"ỳýỵỷỹđ]"
    r"[A-Za-zÀ-ỹ]*s\b",
    re.IGNORECASE
)

hybrid_language_warnings=[]
for item in items:
    for field in ("method","evidence"):
        value=item[field]
        has_vi=bool(vietnamese_diacritic_re.search(value))
        connectors=sorted({m.group(0).lower() for m in english_connector_re.finditer(value)})
        broken=sorted({m.group(0) for m in broken_suffix_re.finditer(value)})
        if has_vi and (connectors or broken):
            hybrid_language_warnings.append({
                "id":item["id"],
                "field":field,
                "english_connectors":connectors,
                "broken_suffix_words":broken,
                "text":value,
            })

status_ok=(
    not broken_links and not dup_ids and not exact and not near
    and len(kit_files)==48 and len(blocks)==288
    and not bad_slugs and severity_levels_ok
    and not calibration_warnings
    and not hybrid_language_warnings
)

result={
    "status":"PASS" if status_ok else "FAIL",
    "kit_file_count":len(kit_files),
    "checklist_item_count":len(blocks),
    "severity_counts":severity_counts,
    "broken_links":broken_links,
    "duplicate_ids":dup_ids,
    "exact_duplicate_content_groups":exact,
    "near_duplicate_content_pairs":near,
    "invalid_slug_files":bad_slugs,
    "all_severity_levels_present":severity_levels_ok,
    "calibration_warnings":calibration_warnings,
    "hybrid_language_warnings":hybrid_language_warnings,
}
(ROOT/"validation-report.json").write_text(
    json.dumps(result,ensure_ascii=False,indent=2),
    encoding="utf-8"
)
print(json.dumps(result,ensure_ascii=False,indent=2))
raise SystemExit(0 if result["status"]=="PASS" else 1)
