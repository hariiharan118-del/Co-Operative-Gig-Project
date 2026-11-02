# Temporary builder — deleted after generating translation JSON files.
import json
from pathlib import Path

ROOT = Path(r"e:\SIH\Worker\assets\translations")
en = json.loads((ROOT / "en.json").read_text(encoding="utf-8"))


def apply(mapping: dict) -> dict:
    missing = []

    def walk(obj):
        if isinstance(obj, dict):
            return {k: walk(v) for k, v in obj.items()}
        if isinstance(obj, str):
            if obj in mapping:
                return mapping[obj]
            missing.append(obj)
            return obj
        return obj

    out = walk(en)
    if missing:
        raise SystemExit("Missing translations:\n" + "\n".join(repr(s) for s in missing))
    return out


def dump(code: str, mapping: dict) -> None:
    data = apply(mapping)
    text = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    (ROOT / f"{code}.json").write_text(text, encoding="utf-8")
    print(f"wrote {code}.json")


TE = {
    "KRIYANTA Partner": "KRIYANTA Partner",
    "98765 43210": "98765 43210",
    "Find work near you": "మీ దగ్గర పని కనుగొనండి",
    "Continue": "కొనసాగించు",
    "Confirm": "నిర్ధారించు",
    "Cancel": "రద్దు",
    "Save": "సేవ్",
    "Delete": "తొలగించు",
    "Edit": "సవరించు",
    "Add": "జోడించు",
    "Back": "వెనక్కి",
    "Retry": "మళ్లీ ప్రయత్నించు",
    "Loading…": "లోడ్ అవుతోంది…",
    "Something went wrong": "ఏదో తప్పు జరిగింది",
    "OK": "సరే",
    "Call": "కాల్",
    "Chat": "చాట్",
    "Next": "తర్వాత",
    "Jobs": "జాబ్‌లు",
    "Earnings": "సంపాదన",
    "History": "చరిత్ర",
    "Support": "సహాయం",
    "Profile": "ప్రొఫైల్",
    "Work with the cooperative": "సహకార సంఘంతో పని చేయండి",
    "Login": "లాగిన్",
    "Register": "రిజిస్టర్",
    "Your name": "మీ పేరు",
    "Phone number": "ఫోన్ నంబర్",
    "Password": "పాస్‌వర్డ్",
    "Log in": "లాగిన్",
    "Create account": "ఖాతా సృష్టించు",
    "Enter your name": "మీ పేరు నమోదు చేయండి",
    "Enter your password": "మీ పాస్‌వర్డ్ నమోదు చేయండి",
    "Forgot password?": "పాస్‌వర్డ్ మర్చిపోయారా?",
    "Send code": "కోడ్ పంపు",
    "Reset code": "రీసెట్ కోడ్",
    "New password": "కొత్త పాస్‌వర్డ్",
    "Resend code": "కోడ్ మళ్లీ పంపు",
    "Reason": "కారణం",
    "You": "మీరు",
    "Online": "ఆన్‌లైన్",
    "Offline": "ఆఫ్‌లైన్",
    "Accept": "అంగీకరించు",
    "Decline": "తిరస్కరించు",
    "Recenter": "మధ్యకు తీసుకురా",
    "Navigate": "నావిగేట్",
    "Send": "పంపు",
    "Name": "పేరు",
    "Phone": "ఫోన్",
    "State": "రాష్ట్రం",
    "City": "నగరం",
    "Upload": "అప్‌లోడ్",
    "Pending": "పెండింగ్",
    "Language": "భాష",
    "At least 8 characters": "కనీసం 8 అక్షరాలు",
    "Reset password": "పాస్‌వర్డ్ రీసెట్",
    "Confirm password": "పాస్‌వర్డ్ నిర్ధారించు",
    "Update password": "పాస్‌వర్డ్ అప్‌డేట్",
    "Enter the 6-digit code": "6 అంకెల కోడ్ నమోదు చేయండి",
    "Passwords do not match": "పాస్‌వర్డ్‌లు సరిపోలలేదు",
    "Could not continue": "కొనసాగించలేకపోయాం",
    "Verification": "వెరిఫికేషన్",
    "Job feed": "జాబ్ ఫీడ్",
    "Active job": "ప్రస్తుత జాబ్",
    "Continue job": "జాబ్ కొనసాగించు",
    "Start job": "జాబ్ ప్రారంభించు",
    "Complete job": "జాబ్ పూర్తి చేయి",
    "Completed": "పూర్తయింది",
    "Job chat": "జాబ్ చాట్",
    "Welfare": "సంక్షేమం",
    "Enrolled": "నమోదైంది",
    "Not enrolled": "నమోదు కాలేదు",
    "Category": "వర్గం",
    "Description": "వివరణ",
    "Submitted": "సమర్పించబడింది",
    "Approved": "ఆమోదించబడింది",
    "Rejected": "తిరస్కరించబడింది",
    "Paid": "చెల్లించబడింది",
    "Past jobs": "గత జాబ్‌లు",
    "Log in to your account": "మీ ఖాతాలో లాగిన్ అవ్వండి",
    "Create a worker account": "వర్కర్ ఖాతా సృ�    "Create a worker account": "వర్కర్ ఖాతా సృష్టించండి",
    "Signing you in": "మిమ్మల్ని సైన్ ఇన్ చేస్తున్నా�ైన్ ఇన్ చేస్తున్నాం",
    "Creating your account": "మీ ఖాతా సృష్టిస్తున్నాం",
    "Please wait a moment.": "దయ�్తున్నాం",
    "Please wait a moment.": "దయచేసి ఒక్క క్షణం వేచి ఉం� "Creating your account": "మీ ఖాతా సృష్టిస్తున్నాం",
    "Please wait a moment.": "దయచేసి �ృష్టిస్తున్నాం",
    "Please wait a moment.": "దయచేసి ఒక్క క్షణం వేచి ఉండండి.",
    "Sending reset code": "రీసెట్ కోడ్ పంపు�
    "Sending reset code": "రీసెట్ కోడ్ పంపుతున్నాం",
    "Updating password": "పాస్‌వర్డ్ అప్‌డేట్ అవు�ం",
    "Updating password": "పాస్‌వర్డ్ అప్‌డేట్ అవుతోంది",
    "Checking your status": "మీ స్థితి చూస్తున్నాం",
    "Refresh status": "స్థితి రిఫ్రెష్",
    "Find nearby work": "దగ్గరలో పని కనుగొనండి",
    "Nearby jobs": "దగ్గరలోని జాబ్‌లు",
    "No active job": "ప్రస్తుత జాబ్ లేదు",
    "On the way": "దారిలో ఉన్నారు",
    "Job in progress": "జాబ్ జరుగు� "Job in progress": "జాబ్ జరుగుతోంది",
    "Your wallet": "మీ వాలెట్",
    "Wallet balance": "వాలెట్ బ్యాలెన్స్",
    "Request payout": "పేఅవుట్ అడగం��ి",
    "Payout requested": "పేఅవుట్ అభ్యర్��ించబడింది",
    "Type a message": "మెసేజ్ �ెన్స్",
    "Request payout": "పేఅవుట్ అడగండి",
    "Payout requested": "పేఅవుట్ అభ్యర్థించబడింది",
    "Type a message": "మెసేజ్ టైప్ చేయండి",
    "Primary skill": "ప్రధాన నైపుణ్యం",
    "Skills": "నైపు� నైపుణ్యం",
    "Skills": "నైపుణ్యాలు",
    "Select state": "రాష్ట్రం ఎంచుకోండి",
    "Select city": "నగరం ఎంచుకోండి",
    "Save profile": "ప్రొఫైల్ సేవ్ చేయండి",
    "Profile saved": "ప్రొఫైల్ సేవ్ అయింది",
    "Document name": "డాక్యుమెం�ింది",
    "Document name": "డాక్యుమెంట్ పేరు",
    "Log out": "లాగ్ అవుట్",
    "App language": "యాప్ భాష",
}

MAPS = {"te": TE}

if __name__ == "__main__":
    for code, mapping in MAPS.items():
        dump(code, mapping)
