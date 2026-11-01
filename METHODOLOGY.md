# Yapay zekâ ile sayısal tasarım metodolojisi (fpga-method v0.4)

Sürüm 0.4 · 2026-11-01 · Durum: pilot öncesi. **PİLOT** etiketli maddeler ilk projede doğrulanır.

Bu metin bir kitin parçasıdır. Kit, yeni bir AMD/Xilinx FPGA (gerekirse Zynq PS) projesini başlatmak
ve yürütmek için bir Claude ajanına verilir. Ajan bu metni okur, kullanıcıyla projeyi konuşur, bir
**profil** seçer, projeyi **şablondan** kurar ve (profil gerektiriyorsa) yürütür.

---

## 0. Kit ve kullanımı

### 0.1 Kitin parçaları

| Parça | Ne | Nerede |
|---|---|---|
| Metodoloji | Bu metin: ilkeler, profiller, süreç, roller | `METHODOLOGY.md` |
| Kanonik ağaç | Her projede aynı olan klasör/dosya listesi ve hangi profilde var olduğu | `manifest.toml` |
| Şablonlar | Kanonik ağacın dosyaları (doküman şablonları, flow script'leri, TB çerçevesi, skill'ler) | `template/` |
| Roller | Rollerin görevi, yetkisi, seviyeye göre modeli ve eforu (tek kaynak) | `agents/roles.toml`, `agents/roles/*.md` |
| Kurulum aracı | Profilden projeyi üretir; profili büyütür | `tools/new_project.py` |
| Makine ayarları | Model id'leri, Vivado/Ross sürümleri ve yolları | `kit_config.toml` |

Neden şablon ve araç: Claude iskeleti her projede düz metinden yeniden yazarsa hem token harcanır
hem de projeler birbirinden farklılaşır. Kurulum aracı aynı iskeleti saniyede üretir; Claude yalnızca
projeye özel içeriği yazar (CMMI'deki "kurum standart süreci + projeye uyarlama" mantığı).

### 0.2 Başlangıç akışı

1. Kullanıcı bu kiti (yolu veya git reposu) ve projenin tarifini bir Claude oturumuna verir.
2. Claude kısa bir keşif yapar (§4.1) ve **profili önerir**: ağırlık × ekip × teslimler (§2).
   Kullanıcı onaylar veya değiştirir.
3. Claude `tools/new_project.py` ile projeyi kurar (§0.3), Ross skill'lerini sabitler, ilk commit'i atar.
4. Claude projeye özel içeriği yazar: `AGENTS.md` proje bloğu, `docs/input/` (gereksinimler),
   seçilen ağırlığa göre `docs/output/` ve özellik spesifikasyonları.
5. Ekip seviyesine göre iş yürütülür (§4). L4'te Claude başlangıç prompt'unu yazar ve çekilir.

### 0.3 Kurulum aracı

```
python3 <kit>/tools/new_project.py --name <ad> --dest <klasör> \
    --weight light|standard|comprehensive --team L1|L2|L3|L4 \
    --deliver ip,board,hwtest,sw --with xilinx_ip,hls,wiki \
    --prefix <önek> --part <parça> --clock-mhz <MHz> [--board <kart>] \
    --features <özellik[:simple|medium|hard]>,... --summary "<tek paragraf>" --git [--with-ross]
python3 <kit>/tools/new_project.py --existing ...   # profili büyüt / özellik ekle
python3 <kit>/tools/new_project.py --dry-run ...    # yalnızca oluşacak yolları göster
```

- `--existing`: var olan dosyaların üzerine yazmaz. Kit'e ait üç dosya (`AGENTS.md`, `CLAUDE.md`,
  `Makefile`) yeniden üretilir; içlerindeki `project:begin … project:end` bloğu korunur. Ajan
  dosyaları her zaman `roles.toml`'dan yeniden üretilir; rolü başka araca geçen ajanın eski dosyası
  silinir. Bu yüzden **ajan dosyaları elle düzenlenmez**; projeye özel not `AGENTS.md` proje bloğuna,
  kalıcı değişiklik kitteki `roles.toml`'a yazılır.
- Profil küçültülmez (dosya silinmez); yalnızca büyütülür.

---

## 1. Kullanıcıyla çalışma

- Kullanıcı sayısal tasarım mühendisi ve birim yöneticisidir; FPGA/RTL'de güçlüdür. Alan dışı
  konuları sade ve örnekle anlat.
- **Türkçe ve kısa** konuş. Uzun cevap yorar.
- **Kararları sen al.** Teknik ve yöntemsel konularda gerekçeli bir varsayılan seç, kısaca söyle,
  ilerle. Kullanıcıya **ne istediğini** sor (kapsam, öncelik, kabul kriteri), nasıl yapılacağını
  değil. Soruları tek tek sor.
- Geri alınamaz veya pahalı kararlar (profil, Xilinx IP yerine kendi tasarım, milestone onayı,
  `docs/input/` değişikliği) kullanıcı onayı ister.
- Kullanıcının cevabı endüstri pratiğine aykırı, riskli veya gereksiz karmaşıksa gerekçesiyle itiraz et.
  Önerileri bilinen best practice'lere dayandır, kaynağını söyle, ihtiyaca uyarla.
- Kayıtlı bir kararı sessizce değiştirme.
- Kullanıcı dokümanları ayrıntılı okumaz, göz gezdirir: onay isterken ne değiştiğini birkaç satırda özetle.
- Başka yapay zekâlardan gelen incelemelerde yalnızca değiştirdiklerini ve görüş gereken noktaları raporla.
- `main`'e merge, `git push`, sistem paketi kurma: kullanıcı söylemeden yapma.
- Proje dosyaları İngilizce; istisna: insan dokümanları (`docs/output/ip_user_guide.md`,
  `docs/output/knowledge/`, `docs/output/hardware_test_procedure.md`) Türkçe, sinyal/register adları İngilizce.

---

## 2. Profil: üç eksen

Bir proje üç bağımsız seçimle tanımlanır. Profil `AGENTS.md`'nin başında ve `project.toml`'da yazar,
örn. `light × L4 × {code, ip}`.

### 2.1 Ağırlık: ne kadar süreç ve doküman

| Ağırlık | Ne zaman | Özü |
|---|---|---|
| **light** | Bir veya birkaç basit özellik; bir LLM bütün repoyu okuyup anlayabilir; ileride büyümesi beklenmiyor | Spec + RTL + TB + kapılar + kısa kullanım kılavuzu. Wiki, milestone, izlenebilirlik yok |
| **standard** | Birkaç özellik; ileride değiştirilmesi muhtemel | + mimari, arayüz, karar kaydı, codemap, en fazla 2 milestone (M0 + teslim), izlenebilirlik |
| **comprehensive** | Büyük, uzun ömürlü, başkaları da kullanacak | + müşteri ihtiyaçları, proje planı, tam LLM wiki, çok milestone, doğrulama raporu, kapanış raporu |

Ölçüt: **projenin ömrü ve kim kullanacağı.** Zorluk ağırlığı belirlemez; zor ama kısa ömürlü bir
deneme `light` olabilir.

### 2.2 Ekip: işi kim yapar (maliyet kademesi)

| Ekip | Tarif | Claude'un rolü |
|---|---|---|
| **L1** | En doğru, en hızlı | Her şeyi Claude yapar (Opus planlar/inceler, Sonnet üretir, Haiku mekanik işler) |
| **L2** | Doğru ve daha ucuz | Claude mimariyi, spesifikasyonu, incelemeyi ve `hard` özellikleri yapar; üretimin büyüğü ücretsiz modellerde |
| **L3** | En ucuz kontrollü yol | Claude mimariyi, spesifikasyonu ve **kilitli kabul testbench'ini** yazar; ücretsiz modeller RTL'i bu testbench geçene kadar iterasyonla düzeltir |
| **L4** | Serbest | Claude kısa keşif yapar, projeyi kurar, başlangıç prompt'unu yazar ve çekilir; işi kullanıcı ücretsiz modellerle yürütür |

**Zorluk, mümkün ekipleri sınırlar.** Ölçüt: protokol veya algoritma karmaşıklığı.

| Zorluk | Örnek | Mümkün ekip |
|---|---|---|
| hard | TCP/IP yığını, karmaşık durum makineleri ve protokoller, yeni algoritma | L1, L2 (L3 riskli, L4 değil) |
| medium | AXI köprüleri, paket ayrıştırıcılar, DMA | L1–L3 |
| simple | UART, sayaç, register bloğu, basit FIFO sarmalayıcı | L1–L4 |

Kullanıcı mümkün olanlar arasından önceliğine göre seçer: doğruluk ve hız → L1, maliyet → daha yüksek
L. Zorluk etiketi özellik başına da konur (`difficulty:` spec frontmatter'ında): L2'de `hard` özelliğin
RTL'ini `senior-engineer` (Sonnet) yazar.

### 2.3 Teslimler: ne teslim edilecek

| Teslim | Eklenen yollar | Eklenen kapı |
|---|---|---|
| `code` (her zaman) | `hw/rtl/`, `hw/tb/`, `hw/constraints/ooc/` | lint, sim, OOC timing |
| `ip` | `hw/ip_package/`, `hw/constraints/ip/` | `make ip`: paketleme + blok tasarımda doğrulama + OOC sentez |
| `board` | `hw/boards/<kart>/`, `hw/constraints/ip/`, `flow/vivado/build_board.tcl` | `make impl`: tam implementasyon, timing, bitstream |
| `hwtest` | `utils/`, `docs/output/hardware_test_procedure.md` | kartta test prosedürü |
| `sw` | `sw/driver/` (HAL üzerinden C), `sw/apps/` | derleme (+ DPI-C ile simülasyon) |

**Seçenekler** (`--with`): `xilinx_ip` (`hw/xilinx_ip/`), `hls` (`hw/hls/`), `wiki` (standard'da tam wiki).

---

## 3. Kanonik ağaç ve profil matrisi

**Kural: her yolun her projede aynı anlamı var. Profil yalnızca var/yok kararını verir; bir dosya ya
kanonik yerindedir ya da yoktur.** Yeni dosyalar yalnızca genişleme noktalarına eklenir (yeni özellik
klasörü, `docs/output/` altına yeni doküman). Klasör adlarında numara kullanılmaz.

```
<proje>/
├── AGENTS.md  CLAUDE.md  project.toml  Makefile  .gitignore  .mcp.json  opencode.json
├── .claude/        agents/ (Claude rolleri), skills/ (proje + Ross skill'leri), settings.json
├── .opencode/      agents/ (ücretsiz model rolleri)
├── docs/
│   ├── input/      kurulumda oluşur, değişikliği onaya bağlı
│   │               external/, customer_needs, system_requirements, constitution, coding_rules,
│   │               development_environment, project_plan
│   └── output/     tasarımda üretilir
│                   specs/<özellik>.md, architecture, interface_control, decision_record,
│                   verification_plan, verification_report, project_close, ip_user_guide (TR),
│                   knowledge/ (TR), hardware_test_procedure (TR)
├── hw/
│   ├── rtl/        common/, <özellik>/, top/          (her klasörde files.f)
│   ├── tb/         common/ (SV çerçeve), <özellik>/, top/, acceptance/ (L3, kilitli)
│   ├── constraints/ ooc/, ip/
│   ├── xilinx_ip/  hls/<kernel>/  ip_package/  boards/<kart>/
├── sw/             driver/, apps/ (baremetal, linux)       ürün yazılımı
├── utils/          host/, target/                          test araçları (teslim edilmez)
├── flow/           vivado/, sim/, checks/, gen/, git/, tools/   otomasyon
├── tracking/       tasks/, model_scorecard, problem_reports, schedule, <milestone>/exit_record
│                   (proje sırasında; kapanışta damıtılır ve silinir)
├── llm/            wiki/ (SCHEMA, index, log, codemap/, xilinx/, protocols/, lessons/), raw/
├── third_party/    ross-ai-assistant/ (git submodule, sabitlenmiş sürüm)
└── build/          git-ignored: Vivado projesi, IP çıktısı, raporlar, log'lar
```

Profil matrisi (✓ var · – yok · E ekibe göre · T teslime göre · S seçenekle). Kesin liste `manifest.toml`'dadır.

| Yol | light | standard | comprehensive |
|---|---|---|---|
| `AGENTS.md`, `CLAUDE.md`, `project.toml`, `Makefile`, `.mcp.json` | ✓ | ✓ | ✓ |
| `opencode.json`, `.opencode/agents/` | E (L2–L4) | E | E |
| `.claude/skills/` proje skill'leri | – | ✓ | ✓ |
| `docs/input/system_requirements, constitution, coding_rules` | ✓ | ✓ | ✓ |
| `docs/input/development_environment, project_plan` | – | ✓ | ✓ |
| `docs/input/customer_needs` | – | – | ✓ |
| `docs/output/specs/`, `ip_user_guide` | ✓ | ✓ | ✓ |
| `docs/output/architecture, interface_control, decision_record, verification_plan` | – (spec içinde) | ✓ | ✓ |
| `docs/output/verification_report, project_close, knowledge/` | – | – | ✓ |
| `hw/rtl/common, hw/tb/common, hw/constraints/ooc` | ✓ | ✓ | ✓ |
| `hw/rtl/top, hw/tb/top` | – | ✓ | ✓ |
| `hw/tb/acceptance/` | E (L3) | E (L3) | E (L3) |
| `hw/ip_package, hw/boards, sw, utils` | T | T | T |
| `hw/xilinx_ip, hw/hls` | S | S | S |
| `flow/` gate script'leri (lint, sim, OOC, locks, env) | ✓ | ✓ | ✓ |
| `flow/` trace, coverage, doc-check, codemap, wiki-lint | – | ✓ | ✓ |
| `tracking/tasks, model_scorecard` | E (L2–L4) | E | E |
| `tracking/problem_reports, schedule, exit_record` | – | ✓ | ✓ |
| `llm/wiki/` SCHEMA, index, codemap, lessons | – | ✓ | ✓ |
| `llm/wiki/xilinx, protocols`, `llm/raw/` | – | S (wiki) | ✓ |

Her dosyanın tek şablonu var; hafif profilde aynı şablonun daha az bölümü gelir, başlıklar aynı sırada.

---

## 4. Süreç

### 4.0 Süreç matrisi

| Faaliyet | light | standard | comprehensive |
|---|---|---|---|
| Keşif | 10–15 dk, kapsam + arayüz + kabul | normal | tam liste (§4.1) |
| Planlama kaydı | yok | yok (kararlar doğrudan dokümanlara) | var + temiz alt ajanla bağımsız inceleme |
| Kurulum | araç + spec | + mimari, ICD | + müşteri ihtiyaçları, plan, wiki kaynakları |
| Milestone | yok (tek teslim, tag) | M0 + teslim | M0 … Mn + teslim |
| Kapı seti | lint, sim, OOC, locks | + coverage, trace, doc-check | aynı + milestone'da tam regresyon |
| Wiki | yok | codemap + lessons | tam: IP/protokol çalışmasından önce ingest |
| Çıkış incelemesi | son inceleme | kısa çıkış kaydı | tam çıkış kaydı + exit-reviewer |
| Kapanış | kılavuz kontrolü | PR → regresyon testi, lessons | + doğrulama raporu, kapanış raporu, kit'e geri bildirim |

### 4.1 Keşif

- Claude Code'da, proje klasöründe yapılır; belgeler sohbete değil klasöre konur (§10).
- Tek, bütünlüklü bir konuşmadır; yöntem bu metinde hazır olduğu için yalnızca projeye özel konular konuşulur.
- Konular (ağırlığa göre kısaltılır): kullanım senaryosu; hedef donanım ve saatler; öncelikler
  (throughput/gecikme/kaynak/güç); kapsam (zorunlu, istenirse, kapsam dışı); Xilinx IP ve lisans;
  kullanıcı arayüzü (veri, kontrol/register, kesmeler); saat/reset mimarisi; sağlamlık; doğrulama ve
  kabul kriterleri; yazılım; milestone ve öncelik sırası; **profil**.
- Kararlar, gerekçeleri ve reddedilen alternatifler kaybolmaz (comprehensive'de planlama kaydı,
  diğerlerinde doğrudan `docs/input/` ve `decision_record.md`).

### 4.2 Kurulum

`new_project.py` ile iskelet; ardından `flow/tools/ross_setup.sh` (Ross sabitleme), `make env-check`.
Claude doldurur: `AGENTS.md` proje bloğu, `docs/input/system_requirements.md` (EARS, ID'li),
`docs/input/constitution.md` ve `coding_rules.md` (gerekirse projeye göre ek), ağırlığa göre
`docs/output/` ve özellik spesifikasyonları. Planlama kaydı kullanıldıysa her bölümün nereye taşındığı
bir tabloyla gösterilir, onaydan sonra kayıt silinir.

### 4.2a Oturumlar: kuran oturum ve yapan oturumlar

- **Kurulum oturumu** (keşif + kurulum + dokümanlar) bittiğinde kapanır. Son işi
  `tracking/status.md`'ye "sıradaki adım"ı yazmaktır.
- **İş oturumları** proje klasöründe yeni bir Claude Code oturumudur. `CLAUDE.md` → `AGENTS.md`
  otomatik yüklenir; oturum `tracking/status.md`'yi okur ve kaldığı yerden devam eder. Kullanıcının
  yazacağı prompt tek satırdır ("devam et" / "M1'e başla"); uzun prompt gerekmez, çünkü her şey dosyalarda.
- Yeni iş oturumu: her milestone'da, light'ta birkaç özellikte bir ve bağlam büyüdüğünde (önce status güncellenir).
- L4'te iş oturumu Claude değil, opencode/VS Code'dur; ilk mesaj `tracking/start_prompt.md`'dir.

### 4.3 Milestone'lar (standard, comprehensive)

- **M0 Altyapı:** flow'lar çalışıyor, TB çerçevesi, ilk register bloğu, kapılar ve riskli varsayımların
  erken denemeleri: en zor saat/genişlikte OOC timing, Xilinx IP seçenek/port/saat davranışı, IP
  lisansları (sürüm dahil), temiz kurulum testi; L2–L3'te `opencode run` ve ajan izinleri.
- Her milestone görülebilir bir sonuç verir; ana hedefe giden yol önce, teslim milestone'u en sonda.
- Tahmin ve gerçekleşme "aktif çalışma günü" olarak `tracking/schedule.md`'de.
- Çıkış: `milestone-exit` skill'i: tam regresyon, çıkış kaydı, dondurulan yollar, exit-reviewer,
  kullanıcı onayı, tag. Dondurulan yolların değişikliği onaya bağlıdır (`make check-locks` denetler).
- Her milestone yeni oturumda başlar; bilgi oturumda değil dosyalarda yaşar.
- Araç (Vivado, Ross, model) sürümü milestone ortasında değişmez (§8.3).

### 4.4 Özellik akışı (L1–L3)

1. `new-feature` skill'i / `flow/gen/new_feature.py`: kanonik klasörler, `files.f`, spec şablonu.
2. spec-writer spesifikasyonu yazar (EARS gereksinimleri `- [ID] metin {by: test|review|analysis}`,
   arayüz, davranış, hata/zaman aşımı, test planı, coverage hedefi). L3'te kabul TB'si de yazılır.
3. Görev kartı (`task-card` skill'i), dispatch (§6).
4. rtl-designer RTL'i yazar; verification **RTL'e bakmadan** spesifikasyondan TB yazar (ayrı ajan; L2–L4'te farklı model).
5. `make gates FEATURE=<f>`: ham sonuç satırları `build/gates/<f>.txt`.
6. reviewer inceler (derinlik ekibe göre, §7.4). Türetilmiş gereksinimleri Claude her durumda okur.
7. (standard+) `make codemap`, kart notları.

### 4.5 L4 akışı

1. Kullanıcı işi anlatır; Claude kısa keşif yapar.
2. Projeyi kurar, spesifikasyonu yazar (L4'te de spec Claude'un kısa keşfinden doğar; ayrıntıyı
   ücretsiz spec-writer genişletir).
3. `tracking/start_prompt.md`'yi doldurur ve kullanıcıya verir; çekilir.
4. İsterse kullanıcı sonda genel değerlendirme ister (Claude reviewer olarak tek seferlik).

### 4.6 Kapanış

`tracking/` kapanışta damıtılıp silinir (git geçmişinde kalır):

| tracking/ | Nereye |
|---|---|
| `problem_reports.md` | her PR için regresyon testi (`hw/tb/`) + öğreticiler `llm/wiki/lessons/` |
| `<milestone>/exit_record.md` | `docs/output/verification_report.md` |
| `schedule.md` | `docs/output/project_close.md` |
| `model_scorecard.md` | `project_close.md` özeti + kit'e geri bildirim (§13) |
| `tasks/` | hiçbir yere |

---

## 5. Roller, modeller, efor

Roller sabittir; seviye yalnızca her rolün aracını ve modelini değiştirir. Tek kaynak
`agents/roles.toml`; kurulum aracı Claude modeli olan rolü `.claude/agents/`'a, ücretsiz modeli
olanı `.opencode/agents/`'a yazar. Tecrübeli/tecrübesiz mühendis ayrımı: sistem tasarımı,
spesifikasyon ve kritik inceleme tecrübeliye (Claude); üretim ve rutin işler tecrübesize
(ücretsiz modeller). En kötü durumda bile (L3) mimariyi Claude yapar.

| Rol | Görev | Yazabildiği | L1 | L2 | L3 | L4 |
|---|---|---|---|---|---|---|
| architect | Gereksinim, mimari, arayüz, özellik bölümleme | `docs/output/` mimari dosyaları | Opus · max | Opus · max | Opus · max | Qwen |
| spec-writer | Özellik spec'i, test planı, görev kartları; L3'te kabul TB | `docs/output/specs/`, `hw/tb/acceptance/`, kartlar | Opus · high | Opus · high | Sonnet · high | Qwen |
| rtl-designer | RTL | `hw/rtl/`, sonuç kartı | Sonnet · medium | Qwen (`hard`: senior-engineer) | Qwen | Qwen |
| verification | TB (RTL okumadan) | `hw/tb/` (acceptance hariç), sonuç kartı | Sonnet · medium | DeepSeek | DeepSeek | DeepSeek |
| reviewer | Bağımsız özellik incelemesi | inceleme kartı | Opus · high | Sonnet · high | DeepSeek | DeepSeek |
| vivado-runner | Flow koşturma, log özeti | `build/` | Haiku | DeepSeek · low | DeepSeek · low | DeepSeek · low |
| wiki-maintainer | Wiki ingest, codemap notları, lint | `llm/wiki/` | Haiku | DeepSeek · low | DeepSeek · low | DeepSeek · low |
| doc-writer | İnsan dokümanı (TR) | kılavuz, knowledge, test prosedürü | Sonnet · medium | DeepSeek · low | DeepSeek · low | DeepSeek · low |
| doc-checker | Dokümanın spec'e uygunluğu (script'ten sonra) | inceleme kartı | Haiku | Sonnet · medium | Qwen | (yalnız script) |
| exit-reviewer | Milestone çıkışı | çıkış kaydı | Opus · max | Opus · max | Opus · max | – |
| senior-engineer | Yükseltilen kartlar; L2'de `hard` özellikler | kartın yazılabilir yolları | – | Sonnet · high | Sonnet · high | – |

- architect, wiki-maintainer, doc-checker ve exit-reviewer yalnızca standard ve comprehensive'de
  vardır; light'ta mimari spec'in içinde yazılır, doküman kontrolü yalnızca script'tir.
- Ana oturum (Claude Code) Opus'tur: sistem görüşü, dispatch, türetilmiş gereksinim kararları.
- Model seçimi kullanıcının değerlendirmesine dayanır: Qwen fonksiyonda güvenilir, hijyeni zayıf →
  RTL'e; DeepSeek hijyen bilgisi, sunumu ve 1M bağlamı iyi, fonksiyonda hata yapar → TB, belge, log,
  wiki. RTL ve TB L2–L4'te farklı modelde; L1'de ikisi de Sonnet ama ayrı ajan bağlamında (TB ajanı
  RTL'i okumaz) ve Opus incelemesiyle.
- Efor alanları: Claude ajanlarında `effort:` frontmatter'ı; opencode'da yalnızca `low` için
  `reasoningEffort` (PİLOT: platformun kabul edip etmediği). Ücretsiz modeller varsayılan olarak
  platformun en yüksek eforunda çalışır.
- Opus yalnızca hatası pahalı işlerde; Haiku yalnızca L1'in mekanik işlerinde (L2–L4'te o işler bedava).
- Tablo pilotun ilk hedefidir; model karnesine göre kitte (`roles.toml`) güncellenir.

**Yükseltme zinciri:** ücretsiz model aynı kapıda `max_attempts` (3) denemede geçemezse → senior-engineer
(Sonnet) → ana oturum (Opus). L1'de Sonnet → Opus. L4'te zincir yok: dur ve kullanıcıya bildir.

---

## 6. Devir mekanizması (Claude ↔ ücretsiz modeller)

- Araçlar doğrudan konuşmaz; aynı repo üzerinden **dosyayla** konuşur: görev kartı
  `tracking/tasks/Tnnn.md`, sonuç kartı `Tnnn.result.md`, inceleme `Tnnn.review.md` (şablonlar aynı klasörde).
- Kart: hedef, okunacak girdiler (yalnızca bunlar), yazılabilir yollar, kabul kapıları, deneme limiti.
  Küçük girdi = ucuz çalışma.
- **Dispatch** (`project.toml` → `profile.dispatch`):
  - `manual` (ilk projede): Claude kullanıcıya tek satır verir:
    `opencode run -m <model> --agent <rol> "Execute tracking/tasks/T012.md"`; kullanıcı çalıştırır, "bitti" der.
  - `auto`: Claude aynı komutu terminalde kendisi çalıştırır.
- Ücretsiz modeller alt ajan olarak değil, modeli açıkça belirtilen ana ajan olarak çalışır (opencode'da
  alt ajanların yanlış modele düştüğü bildirilmiş hatalar var).
- Her görev kendi dalında. Commit `flow/git/commit.sh <rol> <kart> "<mesaj>"` ile: Model/Role/Task
  satırlarını model değil script yazar (bilgi ajan dosyasından ve `project.toml`'dan).
- Claude kontrolde sonuç kartını ve `build/gates/<f>.txt`'yi okur; ücretsiz modelin yazdığı kartta
  kapıları kendisi yeniden koşturur (beyan kanıt değildir). Kodu ekibe göre okur (§7.4).
- Sigortalar: ajan dosyasındaki `steps` limiti, karttaki deneme limiti, yol bazlı yazma izinleri.

---

## 7. Kalite ilkeleri

### 7.1 LLM nitelendirilmemiş bir araçtır
DO-254'teki araç değerlendirme mantığı: nitelendirilmemiş bir tasarım aracının çıktısı bağımsız bir
yolla doğrulanmadan kabul edilmez. Bağımsız yol: script kapısı, farklı model, inceleme. Hiçbir modelin
"test ettim / geçti" beyanı kabul edilmez; kapı yalnızca script çıktısıyla kapanır. (Yön, otoritelerle
uyumlu: EASA'nın 2026 kavram belgesi taslağı genel amaçlı LLM'leri en düşük güvence seviyelerinde tutuyor.)

### 7.2 Kapılar (hepsi `*_RESULT: PASS|FAIL` satırı basar)

| Kapı | Komut | Profil |
|---|---|---|
| Lint (Verilator + Vivado) | `make lint FEATURE=<f>` | hepsi |
| Simülasyon (xsim; tek `TB_RESULT: PASS`) | `make sim FEATURE=<f>` (`SIM=verilator` hızlı birim test) | hepsi |
| OOC timing (spec saatinde, place & route) | `make ooc FEATURE=<f>` | hepsi |
| Kilitli yollar | `make check-locks` | hepsi |
| Coverage (spec'teki hedef) | `make gates` içinde | standard+ |
| İzlenebilirlik (testi olmayan gereksinim, tanımsız ID) | `make trace` | standard+ |
| Doküman adları kodda var mı | `make doc-check` | standard+ |
| IP paketleme + entegrasyon | `make ip FEATURE=<f>` | teslim `ip` |
| Kart implementasyonu | `make impl BOARD=<b>` | teslim `board` |

Eksik araç PASS sayılmaz (`LINT_ALLOW_SKIP=1` yalnızca bilinçli istisna için).

### 7.3 Türetilmiş gereksinim ve bağımsızlık
- Spesifikasyonda olmayan her davranış sonuç kartında `DERIVED-nnn` olarak listelenir; Claude her ekipte okur,
  kabul edilenler spec'e işlenir. Zayıf modellerin "kendi tasarımını uydurmasını" bu yakalar.
- RTL ve TB farklı ajanlar (L2–L4'te farklı modeller); TB spesifikasyondan. opencode'da yol izinleriyle zorunlu; Claude ajanlarında
  talimat + `check-locks` + inceleme ile.
- L3'te kabul TB'si Claude'undur ve kilitlidir; ücretsiz model ek test yazabilir, kabul yalnızca kilitli TB ile.

### 7.4 İnceleme derinliği

| Ekip | Özellik incelemesi | Milestone çıkışı |
|---|---|---|
| L1 | Sonnet yazar, Opus inceler | Opus, tam |
| L2 | Sonnet: özelliğin dosyaları + kapı çıktıları; `hard`'da tam | Opus: çıkış kaydı, coverage, DERIVED, PR; kod riskli modüllerden örneklenir |
| L3 | Claude kodu okumaz; Qwen'in kodunu DeepSeek inceler | L2 gibi, daha hafif |
| L4 | DeepSeek inceler | yok (isteğe bağlı Claude genel değerlendirmesi) |

İnsan dokümanı: her profilde script kontrolü; L1–L2 Claude, L3 Qwen çapraz kontrol.

### 7.5 Kayıtlar
- Hata kaydı `tracking/problem_reports.md` (standard+): kim üretti (rol + model + sürüm), hangi kapı yakaladı.
- Model karnesi `tracking/model_scorecard.md` (L2–L4): model+sürüm başına ilk denemede geçme, deneme sayısı,
  yükseltme, kart dışına çıkma, DERIVED sayısı. Ayrı kalibrasyon yok; ilk gerçek görevler kalibrasyondur.

---

## 8. Araçlar ve sürümler

### 8.1 Araçlar
- **Claude Code** (desktop uygulamasının Code bölümü): Claude rolleri. Pro limitleri çabuk dolar →
  Opus az, oturumlar kısa (§10).
- **opencode**: ücretsiz modeller (kurum sunucuları: Qwen = `general`, DeepSeek = `code`). `AGENTS.md`'yi
  okur; `.claude/skills/`'i de tarar.
- **VS Code**: editör; Claude Code ve opencode terminalinde çalışır; L4'te ücretsiz modeller VS Code'dan
  da kullanılabilir. Ross VS Code eklentisi **kurulmaz** (aşağıya bak).
- **Talimatların tek kaynağı `AGENTS.md`** (kısa; ~150 kural sınırı). `CLAUDE.md` = `@AGENTS.md` +
  Claude'a özel ekler. `.claude/settings.json` `docs/input/**` düzenlemesini onaya bağlar.

### 8.2 AMD Ross: projeye sabitlenir
- Ross skill'leri **projeye** girer: `third_party/ross-ai-assistant/` git submodule, `project.toml`'daki
  sürüm etiketinde; `flow/tools/ross_setup.sh` skill'leri `.claude/skills/`'e bağlar (opencode da okur).
  **Global Ross skill kurulumu yapılmaz** (aynı skill iki kez yüklenir).
- Vivado MCP sunucusu makinede sürüm sürüm yan yana kurulur (`~/tools/ross/<sürüm>/`); her proje
  `.mcp.json` ve `opencode.json`'da kendi sürümünün yolunu gösterir.
- Ross'un tek seferlik uyarısı: MCP sunucusu ile VS Code eklentisini birlikte kullanma.
- Kullanım: `vivado-rtl-lint`, `vivado-simulate-rtl`, `vivado-timing-methodology-checks`,
  `vivado-ip-configurator`, `hw-ila-debug`, `hw-vio-debug`, HLS için `hls-run-flow` vb.
  `vivado-revision-control` ana yöntem değildir: GUI değişikliklerini dışa aktarmak ve yeniden kurulan
  projenin aynı olduğunu doğrulamak için. `vivado_execute` keyfi Tcl çalıştırır: dikkat; MCP ile yapılan
  kalıcı değişiklik commit'lenmiş Tcl/XDC'ye geri yazılır.
- AMD belgeleri `amd-doc-search` ile sorgulanır (sorguya belge numarası), sohbete yüklenmez.

### 8.3 Sürüm kuralı (Vivado, Ross, Verilator, modeller, kit)
- Hepsi `project.toml`'da sabit. Aynı anda farklı sürümlerle çalışan projeler birbirini etkilemez.
- **Milestone ortasında hiçbir araç sürümü değişmez.** Yükseltme yalnızca milestone arasında: yeni
  milestone'un ilk görevi = sürüm değişikliği (`ross_setup.sh <sürüm>`, `project.toml`), tam regresyon,
  karar kaydı (DR). Bu yeni baseline'dır.
- **Uzun süre sonra açılan proje:** önce `make env-check` (Vivado, Ross skill etiketi, MCP ikilisi,
  model id'leri). Eski sürümler duruyorsa onlarla devam; yoksa yukarıdaki yükseltme adımı.
- Ücretsiz modelin takma adının arkasındaki model değişirse: `[models.names]` güncellenir, karnede yeni satır.
- Yeni projeler kitin o günkü sürümleriyle başlar; eski projeler kendi kararıyla yükselir.

---

## 9. LLM wiki

Karpathy'nin "LLM Wiki" kalıbı: ham kaynaklar bir kez okunur, LLM'in yönettiği küçük, bağlantılı sayfalara
derlenir; sorular sayfalardan cevaplanır (RAG gibi her seferinde yeniden keşfedilmez).

- **Amaç 1 (geliştirme):** Xilinx IP/protokol bilgisi bir kez derlenir; ana oturum PDF yerine sayfayı okur.
- **Amaç 2 (gelecek):** eski oturumlar silinmiş olsa da yeni bir oturum projeyi anlar. Çekirdeği codemap.
- İnsan dokümanından ayrıdır: wiki LLM içindir (İngilizce, atomik); insan dokümanı kullanım içindir (Türkçe).
- Kurallar `llm/wiki/SCHEMA.md`; katalog `index.md`; kayıt `log.md`; işlemler ingest / query / lint.
- Codemap kartlarının arayüz bölümü `make codemap` ile koddan üretilir; model yalnızca Amaç/Notlar yazar.
- Ingest ücretsiz modele verilir (DeepSeek 1M bağlam); yazdığı bilgi `status: unverified`, sim/sentezde
  veya Claude incelemesinde teyit edilince `verified`. Kaynak: belge no + sürüm + bölüm.
- Mekanik lint script ile (`make wiki-lint`), içerik tutarlılığı LLM ile.
- light'ta wiki yoktur: proje küçüktür, LLM bütün dosyaları okuyabilir. Bakımı yapılmayan wiki, hiç
  olmamasından kötüdür.

---

## 10. Oturum ve bağlam disiplini

Ölçüm: önceki projede limitin %90'ından fazlası günlerce süren tek oturumda büyüyen bağlamın her mesajda
yeniden okunmasından geldi.

- Büyük girdiler ana oturuma ham girmez: PDF'ler `llm/raw/local/`'e konur ve bir alt ajan veya ücretsiz
  model derler; Claude incelemesi istenirse bunu bir Claude alt ajanı yapar; başka AI incelemeleri dosyaya
  yapıştırılır, önce bulgu listesine çevrilir. Xilinx belgeleri `amd-doc-search` ile.
- Log'lar `build/`'de kalır; vivado-runner özetler; kapı sonuçları tek satırlıktır.
- Büyük dokümanlardan yalnızca gereken bölüm okunur; ajanların "zorunlu okuma" listeleri kısadır.
- Alt ajan yalnızca bağımsızlık (TB, inceleme) veya bağlam koruması için.
- Keşif tek oturum; milestone'lar yeni oturumda.

---

## 11. Sabit teknik tercihler

Projede `docs/input/constitution.md` ve `docs/input/coding_rules.md` olarak durur (tek kaynak orası).
Özet: yalnızca AMD/Xilinx; RTL ve TB SystemVerilog (UVM gerekçeyle); xsim birincil, Verilator lint ve
hızlı birim test; Xilinx IP/XPM önce; KISS ama gerekli özellik çıkarılmaz; hiçbir koşulda kilitlenme yok,
her beklemede zaman aşımı; register haritası tek SV paketinde; repo-first (proje `build/`'de, `add_files`,
IP Tcl'den, BD `write_bd_tcl`, temiz kurulum testi); constraint'ler kart / IP (kapsamlı XDC) / OOC olarak
ayrı; senkron reset, CDC yalnızca XPM veya `ASYNC_REG`'li senkronizatörle, `$clog2` genişlikler;
script'ler AI aracı olmadan düz `make`/Tcl ile çalışır.

## 12. Yazılım (Zynq PS dahil)
Sürücü C, HAL üzerinden (aynı sürücü PS'te, PC'de ve DPI-C ile simülasyonda); XSA script ile; bare-metal
Vitis; PetaLinux/Yocto'da yalnızca yapılandırma git'e girer. Test yazılımı `utils/`'te, ürün yazılımı
`sw/`'de. Ross'un HLS ve Vitis skill'leri kullanılır.

## 13. Git
Her iş kendi dalında; küçük commit'ler; `main`'e yalnızca kullanıcı merge eder; milestone'da tag;
model kaydı commit trailer'ında.

## 14. Kit bakımı
- **Aylık:** Ross sürüm notları (aylık yayın) okunur; yeni sürüm `kit_config.toml`'a yazılır (yalnızca
  yeni projeler etkilenir); işe yarayan yeni skill'ler `agents/roles/*.md`'de ilgili role eklenir.
- Her proje kapanışında `project_close.md`'deki geri bildirim ve model karnesi kite işlenir
  (`roles.toml` model tablosu, şablonlar). Kit sürümü `VERSION`'da; değişiklikler kitin git geçmişinde.
- Kitin kendisi de bir git reposudur; projeler kitin hangi sürümüyle kurulduğunu `project.toml`'da tutar.

## 15. Pilotta doğrulanacaklar
Önerilen pilot: AXI4-Lite UART, `light × L1` ve aynı iş `light × L4` (sonuçlar karşılaştırılır);
sonra checksum + register bloğu ile `standard × L3`.

- [ ] `opencode run -m … --agent …` model/ajan seçiminin gerçekten uygulandığı; opencode model id'leri (`kit_config.toml`)
- [ ] opencode yol bazlı `edit` izinlerinin (glob, son kural kazanır) beklendiği gibi çalıştığı
- [ ] Claude Code ajan `effort:` alanı; opencode `reasoningEffort` platform modellerinde
- [ ] Ross: submodule + `.claude/skills/` symlink (Windows'ta kopya yedeği) ya da proje kapsamlı plugin
- [ ] Ross MCP'nin `.mcp.json` ve `opencode.json`'dan çalışması; `amd-doc-search` URL'si
- [ ] Vivado script'leri (`lint.tcl`, `ooc_synth.tcl`, `package_ip.tcl`, `build_board.tcl`) gerçek Vivado'da;
      `get_msg_config -count`, xsim `-L xpm`, Verilator'a XPM kaynaklarının verilmesi, xcrg rapor ayrıştırması
- [ ] Rol tablosu: ücretsiz modellerin ajan olarak RTL/TB/inceleme performansı
- [ ] Görev/sonuç kartı formatı; L4 başlangıç prompt'u
- [ ] `--existing` ile profil büyütme gerçek projede

## 16. Başlarken (bu metni alan Claude için)
1. Metni okuduğunu tek cümleyle teyit et; kitin yerini doğrula (`manifest.toml`, `tools/new_project.py`).
2. Kullanıcıdan projeyi anlatmasını iste. Gerekirse 3–5 soru: ne istiyor, ne teslim edilecek, ne kadar
   yaşayacak, öncelik doğruluk mu maliyet mi.
3. Profili öner (ağırlık × ekip × teslim + seçenekler), tek cümle gerekçeyle; onay al.
4. Kurulum (§4.2), `make env-check`, ilk commit.
5. Ağırlığa göre keşfi tamamla ve dokümanları yaz; ekibe göre yürüt (§4.4) veya L4'te başlangıç prompt'unu
   verip çekil (§4.5).
