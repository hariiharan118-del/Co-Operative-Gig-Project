"""Generate Indic locale JSON from IAST rows. Run: python tool/gen_locales.py"""

from __future__ import annotations

import json
import sys
from copy import deepcopy
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _iast import iast

LANGS = ("te", "kn", "ml", "mr", "bn", "gu", "pa")

CUSTOMER_DIR = Path(r"e:\SIH\Customer\assets\translations")
WORKER_DIR = Path(r"e:\SIH\Worker\assets\translations")


def flatten(d: dict, prefix: str = "") -> dict[str, str]:
    out: dict[str, str] = {}
    for key, val in d.items():
        path = f"{prefix}.{key}" if prefix else key
        if isinstance(val, dict):
            out.update(flatten(val, path))
        else:
            out[path] = val
    return out


def unflatten(flat: dict[str, str]) -> dict:
    root: dict = {}
    for path, val in flat.items():
        cur = root
        parts = path.split(".")
        for part in parts[:-1]:
            cur = cur.setdefault(part, {})
        cur[parts[-1]] = val
    return root


def render(value: str | None, english: str, script: str) -> str:
    if value is None:
        return english
    return iast(value, script)


def emit(en_path: Path, rows: dict[str, tuple], dest_dir: Path) -> None:
    english = json.loads(en_path.read_text(encoding="utf-8"))
    en_flat = flatten(english)
    missing = sorted(set(en_flat) - set(rows))
    extra = sorted(set(rows) - set(en_flat))
    if missing or extra:
        raise SystemExit(f"{en_path.name} key mismatch missing={missing} extra={extra}")
    for lang in LANGS:
        idx = LANGS.index(lang)
        flat = {
            key: render(rows[key][idx], en_flat[key], lang) for key in en_flat
        }
        obj = unflatten(flat)
        out = dest_dir / f"{lang}.json"
        out.write_text(
            json.dumps(obj, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        json.loads(out.read_text(encoding="utf-8"))
        print("wrote", out, "keys", len(flat))


# Each value is (te, kn, ml, mr, bn, gu, pa) or None to keep English.
# Diacritics: ā ī ū ē ō ṃ ḥ ṅ ñ ṭ ḍ ṇ ś ṣ ḷ ḻ ṟ ṛ ẏ

C: dict[str, tuple] = {
    "appName": (None, None, None, None, None, None, None),
    "tagline": (
        "mī sthānika sahakāra saṃghaṃ nuṃci nammakamaina iṃṭi sahāyaṃ",
        "nimma sthaḷīya sahakāra saṃghadiṃda naṃbikasta gṛha sahāya",
        "niṅṅaḷuṭe prādēśika sahakaraṇa saṃghattil ninnuḷḷa viśvasta gārhika sahāyaṃ",
        "tumcyā sthānika sahakārī saṃsthēkaḍūn viśvāsārha ghargutī madat",
        "āpanār sthānīẏa samabāẏa thēkē biśvasta gṛha sahāẏatā",
        "tamārī sthānika sahakārī pāsēthī viśvasanīya gharēluṃ madad",
        "tuhāḍī sathānak sahikārī tōṃ bharōsēyōga gharēlū madad",
    ),
    "common.continue": (
        "konasāgiṃcu", "muṃduvarisi", "tuṭaruka", "surū ṭhevā", "cāliẏē yāna", "cālu rākho", "jārī rakhkho",
    ),
    "common.confirm": (
        "nirdhāriṃcu", "dṛḍhīkarisi", "sādhyamākkuka", "puṣṭī karā", "niścita karuna", "puṣṭi karo", "pusaṭī karo",
    ),
    "common.cancel": (
        "raddu", "raddu", "raṭṭākkuka", "rada karā", "bātila", "radda karo", "radd karo",
    ),
    "common.save": (
        "sēv", "uḷisi", "sēv ceyyuka", "jatana karā", "saṃrakṣaṇa", "sācavo", "sēv karo",
    ),
    "common.delete": (
        "tolagiṃcu", "aḷisi", "māykkuka", "kaḍā", "muśe phēla", "kaḍho", "haṭāo",
    ),
    "common.edit": (
        "savariṃcu", "saṃpādisi", "tīruttuka", "saṃpādita karā", "saṃpādana", "saṃpādita karo", "sōdha karo",
    ),
    "common.add": (
        "jōḍiṃcu", "sērisī", "cērkkuka", "uṣē karā", "yōga karuna", "umēro", "jōṛo",
    ),
    "common.back": (
        "venakki", "hiṃde", "tirañcilla", "māgē", "pichanē", "pācho", "vāpasa",
    ),
    "common.retry": (
        "maḷḷī prayatniṃcu", "matte prayatnisi", "viṇṭu śramikkuka", "parata prayatna karā", "ābāra cēṣṭā karuna", "pharī prayatna karo", "phēra kōśiśa karo",
    ),
    "common.loading": (
        "lōḍ avutōṃdi…", "lōḍ āguttide…", "lōḍ ceyyunnu…", "lōḍ hōta āhē…", "lōḍ hōcchē…", "lōḍ thai rahyuṃ chē…", "lōḍ hō rihā hai…",
    ),
    "common.error": (
        "ēdō tappu jarigiṃdi", "ēnō tappāgide", "entō piśāyaṃ saṃbhaviccu", "kāhī cūka jhālī", "kichu bhula haẏēchē", "kāīka bhūla thaī", "kujha galata hō giā",
    ),
    "common.ok": (
        "sarē", "sari", "śari", "ṭhīka", "ṭhika āchē", "sārū", "ṭhīka hai",
    ),
    "common.close": (
        "mūsivēyi", "mucchi", "aṭaykkuka", "baṃda karā", "baṃdha karuna", "baṃdha karo", "baṃda karo",
    ),
    "common.call": (
        "kāl", "kare", "kāl", "kāl", "kāla", "kōla", "kāl",
    ),
    "common.chat": (
        "cāṭ", "cāṭ", "cāṭ", "cēṭ", "cāṭ", "cēṭ", "cait",
    ),
    "common.next": (
        "tarvāta", "muṃde", "aṭutta", "puḍhē", "parabartī", "agāuṃ", "agē",
    ),
    "nav.home": (
        "hōm", "mukhapuṭa", "hōm", "mukhapṛṣṭha", "hōma", "hōm", "hōm",
    ),
    "nav.history": (
        "caritra", "itihāsa", "caritraṃ", "itihāsa", "itihāsa", "itihāsa", "itihāsa",
    ),
    "nav.support": (
        "sahāyaṃ", "sahāya", "sahāyaṃ", "sahāyya", "sahāẏatā", "madad", "madada",
    ),
    "nav.profile": (
        "prōphail", "prōphail", "prōphāil", "prōphāil", "prōphāil", "prōphāil", "prōphāil",
    ),
    "language.title": (
        "mī bhāṣanu eṃcukōṃḍi",
        "nimma bhāṣeyannu āykemāḍi",
        "niṅṅaḷuṭe bhāṣa tiraññeṭukkuka",
        "tumcī bhāṣā nivḍā",
        "āpanār bhāṣā chāṛuna",
        "tamārī bhāṣā pasanda karo",
        "āpaṇī bhāśā cunō",
    ),
    "language.subtitle": (
        "dīnni tarvāta prōphail lō mārcavaccu",
        "idannu naṃtara prōphail nalli badalāyisabahudu",
        "itu pinnīṭ prōphāilil māṟṟāṃ",
        "hē nantarī prōphāil madhyē badalatā yēīl",
        "ēṭā parē prōphāilē badalātē pārēn",
        "ā pachī prōphāilmāṃ badalī śakāśē",
        "ēha bāda vica prōphāil vica badalī sakadē hō",
    ),
    "language.continue": (
        "konasāgiṃcu", "muṃduvarisi", "tuṭaruka", "surū ṭhevā", "cāliẏē yāna", "cālu rākho", "jārī rakhkho",
    ),
    "language.settingsTitle": (
        "bhāṣa", "bhāṣe", "bhāṣa", "bhāṣā", "bhāṣā", "bhāṣā", "bhāśā",
    ),
    "language.settingsHint": (
        "yāp bhāṣa", "aplikēśan bhāṣe", "āp bhāṣa", "yāp bhāṣā", "āpa bhāṣā", "ēp bhāṣā", "ēp bhāśā",
    ),
}

# Auth + remaining customer rows are imported from companion modules if present;
# otherwise defined below in this file after the first dump check.

AUTH_HOME = {
    "auth.welcomeTitle": (
        "KRIYANTA ku svāgataṃ",
        "KRIYANTA ge svāgata",
        "KRIYANTA ilēkku svāgataṃ",
        "KRIYANTA madhyē svāgata",
        "KRIYANTA ē svāgataṃ",
        "KRIYANTA māṃ svāgata",
        "KRIYANTA vica jī āiāṃ nūṃ",
    ),
    "auth.welcomeSubtitle": (
        "prāraṃbhiṃcēṃduku lāgin avvaṃḍi lēdā khātā sṛṣṭiṃcaṃḍi",
        "prāraṃbhisalu lāgin māḍi athavā khātē racisi",
        "tuṭaṅṅān lāgin ceyyuka allēṅkil khātā sṛṣṭikkuka",
        "suru karāyālā lāgin karā kimasvā khātē tayāra karā",
        "śuru karatē lāgina karuna athabā hisāba khulun",
        "śaru karavā lāgin karo athavā khātuṃ banāvo",
        "śurū karaṇa laī lāgina karo jāṃ khātā baṇāo",
    ),
    "auth.signInTitle": (
        "mī khātālōki lāgin avvaṃḍi",
        "nimma khātēge lāgin māḍi",
        "niṅṅaḷuṭe khātāyil lāgin ceyyuka",
        "tumcyā khātēta lāgin karā",
        "āpanār hisābē lāgina karuna",
        "tamārā khātāmāṃ lāgin karo",
        "āpaṇē khātē vica lāgina karo",
    ),
    "auth.registerTitle": (
        "mī khātā sṛṣṭiṃcaṃḍi",
        "nimma khātēyannu racisi",
        "niṅṅaḷuṭe khātā sṛṣṭikkuka",
        "tumcē khātē tayāra karā",
        "āpanār hisāba khulun",
        "tamāruṃ khātuṃ banāvo",
        "āpaṇā khātā baṇāo",
    ),
    "auth.loginTab": (
        "lāgin", "lāgin", "lāgin", "lāgin", "lāgina", "lāgin", "lāgina",
    ),
    "auth.registerTab": (
        "namōdu", "nōṃdaṇe", "rājiṣṭar", "nōṃdaṇī", "rajiṣṭāra", "nōṃdhaṇī", "rajisṭar",
    ),
    "auth.invalidCredentials": (
        "muṃduku vellalēdēṃ",
        "muṃduvarisalu sādhyavāgalilla",
        "tuṭaranāyi kazhiññilla",
        "surū ṭhevatā ālē nāhī",
        "āgē yētē pāralāma nā",
        "āgāḷ vadhī śakyā nahi",
        "agē nāṃhī jā sakēā",
    ),
    "auth.verifying": (
        "mimmalni sāin in cēstunnāṃ…",
        "nimma sāin in māḍuttiddēve…",
        "niṅṅaḷe sāin in ceyyunnu…",
        "tumhālā sāin in karaṭ āhōta…",
        "āpanākē sāina ina karā hōcchē…",
        "tamnē sāin in karī rahyā chīē…",
        "tuhānūṃ sāina ina kīta jā rihā hai…",
    ),
    "auth.registering": (
        "mī khātā sṛṣṭistunnāṃ…",
        "nimma khātēyannu racisuttiddēve…",
        "niṅṅaḷuṭe khātā sṛṣṭikkunnu…",
        "tumcē khātē tayāra karaṭ āhōta…",
        "āpanār hisāba khōlā hōcchē…",
        "tamāruṃ khātuṃ banāvī rahyā chīē…",
        "āpaṇā khātā baṇāiā jā rihā hai…",
    ),
    "auth.verifyingBody": (
        "dayavaiṭṭi nirīkṣiṃcaṃḍi, mī ḍāśbōrḍ tō kaluputunnāṃ.",
        "dayaviṭṭu nirīkṣisi, nimma ḍaiśbōrḍ gē saṃparkisuttiddēve.",
        "dayavāyi kāttirlikkuka, niṅṅaḷuṭe ḍaiśbōrḍilēkku baṃdhikkunnu.",
        "kr̥payā thāṃba, āmhī ḍaiśbōrḍaśī jōḍata āhōta.",
        "dayakarē āpēkṣā karuna, āmara ḍaiśbōrḍēra saṅgē yōga karachi.",
        "kr̥payā rāha, amē ḍaiśbōrḍ sāthē jōḍīē chīē.",
        "kirapā kēkē, asīṃ ḍaiśbōrḍ nāla jōṛa rahē hāṃ.",
    ),
    "auth.needHelp": (
        "sahāyaṃ kāvālā?", "sahāya bēkē?", "sahāyaṃ vēṇō?", "madat pāhijē?", "sāhāyya cāi?", "madad jōīē?", "madada cāhīdī hai?",
    ),
    "auth.contactSupport": (
        "sahāyāni saṃpradiṃcaṃḍi",
        "beṃbalavannu saṃparkisi",
        "sapaṃrṭinē baṃdhappeṭuka",
        "sahāyyaśī saṃparka karā",
        "sahāẏatāra saṅgē yōgāyōga karuna",
        "sapaōrṭnē saṃparka karo",
        "sapaōrṭ nāla saṃparka karo",
    ),
    "auth.phoneLabel": (
        "phōn saṃkhya", "phōn saṃkhye", "phōn nambar", "phōn kramaṅka", "phōna nāmbar", "phōn nambar", "phōn nambar",
    ),
    "auth.phoneHint": (None, None, None, None, None, None, None),
    "auth.nameLabel": (
        "pūra pēru", "pūrṇa hesaru", "muzhuvan pēr", "pūrṇa nāva", "pūrṇa nāma", "pūruṃ nāma", "pūrā nāma",
    ),
    "auth.nameHint": (
        "mī pēru", "nimma hesaru", "niṅṅaḷuṭe pēr", "tumcē nāva", "āpanār nāma", "tamāruṃ nāma", "āpaṇā nāma",
    ),
    "auth.passwordLabel": (
        "pāsvard", "pāsvard", "pāsvard", "pāsvard", "pāsaōyārḍ", "pāsvard", "pāsavaraḍ",
    ),
    "auth.passwordHint": (
        "kanniṣṭaṃ 8 akṣarālu",
        "kaniṣṭha 8 akṣaragaḷu",
        "kurāñjatu 8 akṣaraṃ",
        "kamiīta kami 8 akṣarē",
        "kama pakṣē 8 ṭi akṣara",
        "ochāmāṃ ochī 8 akṣara",
        "ghaṭṭō ghaṭṭ 8 akkhara",
    ),
    "auth.loginCta": (
        "lāgin", "lāgin", "lāgin", "lāgin", "lāgina", "lāgin", "lāgina",
    ),
    "auth.registerCta": (
        "khātā sṛṣṭiṃcaṃḍi", "khātē racisi", "khātā sṛṣṭikkuka", "khātē tayāra karā", "hisāba khulun", "khātuṃ banāvo", "khātā baṇāo",
    ),
    "auth.forgotPassword": (
        "pāsvard marcipōyārā?",
        "pāsvard marettira?",
        "pāsvard marannō?",
        "pāsvard visarlāta?",
        "pāsaōyārḍ bhulē gēchēn?",
        "pāsvard bhūlī gayā?",
        "pāsavaraḍ bhulla gē?",
    ),
    "auth.forgotTitle": (
        "pāsvard maruhōdiṃcaṃḍi",
        "pāsvard maruhōdisi",
        "pāsvard rīsēṭ ceyyuka",
        "pāsvard rīseṭ karā",
        "pāsaōyārḍ rīsēṭ karuna",
        "pāsvard rīsēṭ karo",
        "pāsavaraḍ rīsēṭ karo",
    ),
    "auth.forgotSubtitle": (
        "mī mōbail nambaruki kōḍ pampistāṃ",
        "nimma mōbail saṃkhyēge kōḍ kaḷuhisuttēve",
        "niṅṅaḷuṭe mōbāil nambarilēkku kōḍ ayaykkum",
        "tumcyā mōbāil var kramaṅkāvar kōḍ pāṭhavū",
        "āpanār mōbāila nāmbārē kōḍ pāṭhāba",
        "tamārā mōbāil nambar par kōḍ mōkālīśuṃ",
        "āpaṇē mōbāil nambar tē kōḍ bhejāṅgē",
    ),
    "auth.sendResetCode": (
        "rīseṭ kōḍ pampu",
        "maruhōdisuva kōḍ kaḷuhisi",
        "rīsēṭ kōḍ ayaykkuka",
        "rīseṭ kōḍ pāṭhavā",
        "rīsēṭ kōḍ pāṭhāna",
        "rīsēṭ kōḍ mōkalo",
        "rīsēṭ kōḍ bhejo",
    ),
    "auth.resetCodeSent": (
        "{} ki pampina kōḍ ni niviṃcaṃḍi",
        "{} ge kaḷuhisida kōḍa nnamūdisi",
        "{} ilēkku ayaccā kōḍ nalkuka",
        "{} var pāṭhavlēlā kōḍ ṭākā",
        "{} ē pāṭhānō kōḍa ṭāip karuna",
        "{} par mōkālēlō kōḍ nākho",
        "{} tē bhejiā kōḍ pāo",
    ),
    "auth.otpLabel": (
        "rīseṭ kōḍ", "maruhōdisuva kōḍ", "rīsēṭ kōḍ", "rīseṭ kōḍ", "rīsēṭ kōḍ", "rīsēṭ kōḍ", "rīsēṭ kōḍ",
    ),
    "auth.otpHint": (
        "6 aṃkula kōḍ", "6 aṃkiya kōḍ", "6 aṃkattil kōḍ", "6 aṃkī kōḍ", "6 aṃkēra kōḍ", "6 aṃkanō kōḍ", "6 aṃkī kōḍ",
    ),
    "auth.invalidOtp": (
        "4 nuṃci 8 aṃkula kōḍ ni niviṃcaṃḍi",
        "4 riṃda 8 aṃkiya kōḍa nnamūdisi",
        "4 mutal 8 varē aṃkattil kōḍ nalkuka",
        "4 tē 8 aṃkī kōḍ ṭākā",
        "4 thēkē 8 aṃkēra kōḍa ṭāip karuna",
        "4 thī 8 aṃkanō kōḍ nākho",
        "4 tōṃ 8 aṃkī kōḍ pāo",
    ),
    "auth.newPasswordLabel": (
        "kotta pāsvard", "hōsa pāsvard", "putiya pāsvard", "navīna pāsvard", "natuna pāsaōyārḍ", "navuṃ pāsvard", "navāṃ pāsavaraḍ",
    ),
    "auth.confirmPasswordLabel": (
        "kotta pāsvard ni nirdhariṃcaṃḍi",
        "hōsa pāsvardannu dṛḍhīkarisi",
        "putiya pāsvard sādhyamākkuka",
        "navīna pāsvardācī puṣṭī karā",
        "natuna pāsaōyārḍ niścita karuna",
        "navā pāsvardnī puṣṭi karo",
        "navēṃ pāsavaraḍ dī pusaṭī karo",
    ),
    "auth.passwordMismatch": (
        "pāsvard lu sarihōḍaṃ lēvu",
        "pāsvardgaḷu hoṃdikeyāguttilla",
        "pāsvardukal poruttamilla",
        "pāsvard jūḷata nāhīta",
        "pāsaōyārḍ milyāchē nā",
        "pāsvard bhaḷatā nathī",
        "pāsavaraḍ mēla nahīṃ khāṃdē",
    ),
    "auth.resetCta": (
        "pāsvard naviṃcaṃḍi", "pāsvard navīkarisi", "pāsvard apḍēṭ ceyyuka", "pāsvard avhata karā", "pāsaōyārḍ āpaḍēṭ karuna", "pāsvard apḍēṭ karo", "pāsavaraḍ apḍēṭ karo",
    ),
    "auth.resendCode": (
        "kōḍ ni maḷḷī pampu", "kōḍannu matte kaḷuhisi", "kōḍ viṇṭu ayaykkuka", "kōḍ parata pāṭhavā", "kōḍ ābāra pāṭhāna", "kōḍ pharī mōkalo", "kōḍ phēra bhejo",
    ),
    "auth.resetting": (
        "rīseṭ kōḍ pampistunnāṃ…",
        "maruhōdisuva kōḍ kaḷuhisuttiddēve…",
        "rīsēṭ kōḍ ayaykkunnu…",
        "rīseṭ kōḍ pāṭhavata āhōta…",
        "rīsēṭ kōḍ pāṭhānō hōcchē…",
        "rīsēṭ kōḍ mōkalī rahyā chīē…",
        "rīsēṭ kōḍ bhejiā jā rihā hai…",
    ),
    "auth.updatingPassword": (
        "pāsvard naviṃcabadutōṃdi…",
        "pāsvard navīkarisuttide…",
        "pāsvard apḍēṭ ceyyunnu…",
        "pāsvard avhata hōta āhē…",
        "pāsaōyārḍ āpaḍēṭ hōcchē…",
        "pāsvard apḍēṭ thai rahyuṃ chē…",
        "pāsavaraḍ apḍēṭ hō rihā hai…",
    ),
    "auth.resetSuccess": (
        "pāsvard naviṃcabaḍiṃdi. kotta pāsvard tō lāgin avvaṃḍi.",
        "pāsvard navīkarisalāgide. hōsa pāsvardninda lāgin māḍi.",
        "pāsvard apḍēṭ ceytu. putiya pāsvard upayōgiccu lāgin ceyyuka.",
        "pāsvard avhata jhālā. navīna pāsvardānē lāgin karā.",
        "pāsaōyārḍ āpaḍēṭ haẏēchē. natuna pāsaōyārḍē lāgina karuna.",
        "pāsvard apḍēṭ thaī gayuṃ. navā pāsvardthī lāgin karo.",
        "pāsavaraḍ apḍēṭ hō giā. navēṃ pāsavaraḍ nāla lāgina karo.",
    ),
    "auth.devOtpHint": (
        "SMS ālasyam avutundi. ī kōḍ ni vāḍaṃḍi: {}",
        "SMS taḍavāgabahudu. ī kōḍa baḷasi: {}",
        "SMS vilambikkām. ī kōḍ upayōgikkuka: {}",
        "SMS uśira lāgū śakatē. hā kōḍ vāparā: {}",
        "SMS dērī hōtē pārē. ēi kōḍa byabahāra karuna: {}",
        "SMS mōḍuṃ paḍī śakē. ā kōḍ vāparo: {}",
        "SMS cira hō sakadā hai. ēha kōḍ varatō: {}",
    ),
    "auth.invalidPhone": (
        "sariyaina 10 aṃkula mōbail nambar niviṃcaṃḍi",
        "mānya 10 aṃkiya mōbail saṃkhyē nnamūdisi",
        "śariyāya 10 aṃkattil mōbāil nambar nalkuka",
        "yōgya 10 aṃkī mōbāil kramaṅka ṭākā",
        "baidha 10 aṃkēra mōbāila nāmbar ṭāip karuna",
        "mānya 10 aṃkanō mōbāil nambar nākho",
        "sahī 10 aṃkī mōbāil nambar pāo",
    ),
    "auth.invalidName": (
        "mī pēru niviṃcaṃḍi", "nimma hesaru nnamūdisi", "niṅṅaḷuṭe pēr nalkuka", "tumcē nāva ṭākā", "āpanār nāma ṭāip karuna", "tamāruṃ nāma nākho", "āpaṇā nāma pāo",
    ),
    "auth.invalidPassword": (
        "pāsvard kanniṣṭaṃ 8 akṣarālu uṃḍāli",
        "pāsvard kaniṣṭha 8 akṣaragaḷirabēku",
        "pāsvard kurāñjatu 8 akṣaramāyirikkaṇaṃ",
        "pāsvard kamiīta kami 8 akṣarāṃcā asāvā",
        "pāsaōyārḍ kama pakṣē 8 ṭi akṣarēra hōtē habē",
        "pāsvard ochāmāṃ ochī 8 akṣaranuṃ hōvuṃ jōīē",
        "pāsavaraḍ ghaṭṭō ghaṭṭ 8 akkhara dā hōvē",
    ),
    "auth.passwordRequired": (
        "mī pāsvard niviṃcaṃḍi", "nimma pāsvard nnamūdisi", "niṅṅaḷuṭe pāsvard nalkuka", "tumcā pāsvard ṭākā", "āpanār pāsaōyārḍ ṭāip karuna", "tamārō pāsvard nākho", "āpaṇā pāsavaraḍ pāo",
    ),
}

C.update(AUTH_HOME)


def main() -> None:
    # Remaining customer + worker rows loaded from _rows_more if this file is complete.
    from _rows_customer import CUSTOMER_REST
    from _rows_worker import WORKER_ROWS

    customer = dict(C)
    customer.update(CUSTOMER_REST)
    emit(CUSTOMER_DIR / "en.json", customer, CUSTOMER_DIR)
    emit(WORKER_DIR / "en.json", WORKER_ROWS, WORKER_DIR)


if __name__ == "__main__":
    main()
