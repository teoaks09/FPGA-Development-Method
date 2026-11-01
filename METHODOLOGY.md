# Yapay zekâ ile sayısal tasarım yöntemi (fpga-method v0.5)

Durum: dış inceleme ve benchmark öncesi taslak. **PİLOT** etiketli maddeler ilk denemede doğrulanır.

Bu repo bir **kit**tir. Yeni bir AMD/Xilinx FPGA (ve gerekirse Zynq PS) işine başlarken bir Claude
oturumuna bu repo verilir; Claude kullanıcıyla işi konuşur, projeyi şablondan kurar ve seçilen ekip
seviyesine göre yürütür.

## 1. Felsefe

- **İskelet kalın, kurallar ince.** Klasör yapısı, dosya adları, ajanlar, skill'ler ve script'ler
  standarttır ve araçla üretilir. Kurallar ise kısa ve ilke düzeyindedir. Yapay zekâ hızla geliştiği
  için ayrıntılı prosedürler çabuk eskir; ilkeler kalır.
- **Doküman az ve kısa.** Proje başına: gereksinimler, özellik başına kısa spec, tek satırlık
  kararlar, Türkçe README. Başka zorunlu doküman yok.
- **Her şey dosyada.** Bilgi oturumda değil repoda yaşar; yeni bir oturum (veya başka bir model)
  dosyaları okuyup devam edebilir.
- **Claude olmadan da yürür.** Proje, yalnızca ücretsiz modeller ve Vivado olan iç ağa taşınabilir.
  `AGENTS.md` tek başına yeterlidir; script'ler yapay zekâ aracı olmadan çalışır.
- **Model beyanı kanıt değildir.** Bir kontrol yalnızca script'i PASS yazdığında geçer.

## 2. Kitin parçaları

| Parça | Ne |
|---|---|
| `METHODOLOGY.md` | Bu metin |
| `SETUP.md` | Makine kurulumu (bir kez): Vivado/Vitis, Verilator, iverilog, Claude Code, opencode, Ross, GitHub, iç ağ |
| `manifest.toml` + `template/` | Kanonik proje ağacı ve şablonları |
| `agents/roles.toml` + `agents/roles/*.md` | Roller: görev, yazma yetkisi, ekip seviyesine göre model ve efor (tek kaynak) |
| `tools/new_project.py` | Projeyi profile göre kurar; profili sonradan değiştirir (`--existing`) |
| `tools/check_machine.sh` | Makinedeki araçları kontrol eder |
| `kit_config.toml` | Makineye özel: model id'leri, Vivado/Ross sürüm ve yolları |
| `BENCHMARK.md`, `REVIEW_PROMPT.md` | Pilot ölçümü ve dış inceleme için |

## 3. Profil

Profil iki seçimden oluşur ve `AGENTS.md`'nin başında yazar (örn. `L2 × {code, ip} + wiki`).

### 3.1 Ekip seviyesi: işi kim yapar

| Seviye | Claude ne yapar | Ücretsiz modeller ne yapar |
|---|---|---|
| **L1** | Her şeyi (Opus planlar/inceler, Sonnet üretir, Haiku mekanik işler) | — |
| **L2** | Gereksinim, spec, inceleme; `hard` özelliklerin RTL'i | RTL, testbench, log özeti, README |
| **L3** | Gereksinim, spec ve **kilitli kabul testbench'i** | RTL'i kabul testleri geçene kadar iterasyonla düzeltir; ek testler, inceleme |
| **L4** | Kısa keşif, kurulum, başlangıç prompt'u; sonra çekilir | Her şey (kullanıcı yürütür) |

Seviyeyi kullanıcı seçer; Claude önerir. Ölçüt: protokol/algoritma karmaşıklığı işin hangi
seviyelerde yapılabileceğini sınırlar (ör. TCP/IP yığını L1–L2, UART L1–L4); kullanıcı bunların
arasından doğruluk/hız ile maliyet arasında seçer. Özellik bazında `difficulty: simple|medium|hard`
spec'te yazar.

### 3.2 Teslimler ve seçenekler

- Teslim: `code` (her zaman), `ip` (Vivado custom IP), `board` (kart, bitstream), `hwtest`
  (donanım testi), `sw` (sürücü, Zynq PS yazılımı).
- Seçenek: `wiki` (büyük ve uzun ömürlü projede LLM wiki), `xilinx_ip`, `hls`.

Küçük projede wiki gerekmez: bir LLM bütün repoyu okuyabilir. Büyük projede wiki, oturumlar
silindikten sonra yeni bir oturumun projeyi hızlı anlaması içindir (§8).

## 4. Kanonik ağaç

Her projede aynı yollar vardır; profil yalnızca var/yok kararını verir. Bir dosya ya kanonik
yerindedir ya da yoktur. Kesin liste: `manifest.toml`.

```
AGENTS.md  CLAUDE.md  README.md (TR)  project.toml  Makefile  .mcp.json  opencode.json
.claude/        agents/, skills/ (proje + Ross), settings.json
.opencode/      agents/
docs/           requirements.md, coding_rules.md, specs/<özellik>.md, decisions.md, external/
                hardware_test.md (hwtest)
hw/             rtl/<özellik>/, rtl/common/, tb/<özellik>/, tb/common/ (SV çerçeve),
                tb/acceptance/ (L3), constraints/ooc/, constraints/ip/, xilinx_ip/, hls/,
                ip_package/ (ip), boards/<kart>/ (board)
sw/ (sw)        driver/ (C + HAL), apps/
utils/ (hwtest) host/, target/  - teslim edilmeyen test araçları
flow/           vivado/, sim/, checks/, gen/, git/, tools/
tracking/       status.md (her zaman), tasks/ + model_scorecard.md (L2–L4), start_prompt.md (L4)
llm/ (wiki)     wiki/ (SCHEMA, index, log, codemap/, ...), raw/
third_party/    ross-ai-assistant/ (submodule, sabit sürüm)
build/          git-ignored: Vivado projesi ve tüm çıktılar
```

## 5. Süreç

### 5.1 Kurulum oturumu
1. Kullanıcı işi anlatır (belgeler sohbete değil `docs/external/`'a).
2. Claude yalnızca **ne istendiğini** sorar: kapsam, teslim, kabul, ne kadar yaşayacağı, öncelik.
3. Profili önerir; kullanıcı onaylar (**onay 1**).
4. `tools/new_project.py` ile kurar, `flow/tools/ross_setup.sh`, `make env-check`, ilk commit.
5. `docs/requirements.md`'yi yazar; özellikleri `make feature NAME=<f>` ile açar, spec'leri yazar;
   kullanıcı spec'leri onaylar (**onay 2**). L3'te kabul testbench'lerini yazar.
6. `tracking/status.md`'ye sıradaki adımı yazar. Oturum kapanır. L4'te başlangıç prompt'unu verir.

### 5.2 İş oturumları
- Proje klasöründe yeni bir Claude Code oturumu; `CLAUDE.md` → `AGENTS.md` otomatik yüklenir,
  oturum `tracking/status.md`'yi okur. Kullanıcının yazacağı: "devam et".
- Özellik akışı: RTL (rtl-designer) → testbench, spec'ten ve RTL'e bakmadan (verification) →
  `make check FEATURE=<f>` → inceleme (reviewer) → türetilmiş gereksinimlere karar.
- Yeni oturum: bağlam büyüdüğünde veya büyük bir adım bittiğinde (önce `status.md` güncellenir).
- L4'te iş oturumu opencode/VS Code'dur; ilk mesaj `tracking/start_prompt.md`.

### 5.3 Teslim
`deliver` skill'i: bütün kontroller, Türkçe README, kararlar, durum; kullanıcı onaylar ve tag atar
(**onay 3**). Büyük işte ara teslimler aynı şekilde yapılır (milestone = tag).

### 5.4 Sonradan değişiklik
Proje aylar sonra açıldığında: `make env-check` (araç sürümleri), `status.md`, büyük projede
`llm/wiki/index.md`. Profil değişirse (ör. L4 → L2, wiki eklenir) `new_project.py --existing`.

## 6. Roller ve modeller

Tek kaynak `agents/roles.toml`. Kurulum aracı Claude modeli olan rolü `.claude/agents/`'a, ücretsiz
modeli olanı `.opencode/agents/`'a yazar; seviye değişince ajan dosyaları yeniden üretilir (elle
düzenlenmez). L1–L3'te ana oturum (Opus) mimariyi ve kararları tutar.

| Rol | Görev | L1 | L2 | L3 | L4 |
|---|---|---|---|---|---|
| spec-writer | Kısa spec; L3'te kabul TB'si | Opus·high | Opus·high | Sonnet·high | Qwen |
| rtl-designer | RTL | Sonnet·medium | Qwen | Qwen | Qwen |
| verification | TB (RTL okumadan) | Sonnet·medium | DeepSeek | DeepSeek | DeepSeek |
| reviewer | Bağımsız inceleme | Opus·high | Sonnet·high | DeepSeek | DeepSeek |
| vivado-runner | Flow koşturma, kısa özet | Haiku | DeepSeek·low | DeepSeek·low | DeepSeek·low |
| doc-writer | Türkçe README | Sonnet·medium | DeepSeek·low | DeepSeek·low | DeepSeek·low |
| wiki-maintainer (wiki) | Wiki bakımı | Haiku | DeepSeek·low | DeepSeek·low | DeepSeek·low |
| senior-engineer | Yükseltilen işler; L2'de `hard` RTL | — | Sonnet·high | Sonnet·high | — |

- Gerekçe (kullanıcının model değerlendirmesi): Qwen fonksiyonda güvenilir ama hijyeni zayıf →
  RTL; DeepSeek hijyen bilgisi, sunum ve 1M bağlamı iyi ama fonksiyonda hata yapar → TB, log,
  doküman, wiki. RTL ile TB farklı ajanlarda (L2–L4'te farklı modellerde).
- Yükseltme: aynı kontrol 3 denemede geçmezse ücretsiz model → senior-engineer → ana oturum.
  L4'te durup kullanıcıya bildirilir.
- Yeni ücretsiz modeller `kit_config.toml`'a eklenir; tablo benchmark'a göre güncellenir.

## 7. Devir ve kalite

- **Devir dosyayla:** görev kartı `tracking/tasks/Tnnn.md` → sonuç kartı `Tnnn.result.md`. Ücretsiz
  model, modeli açıkça verilen ana ajan olarak çalışır: `opencode run --auto -m <model> --agent <rol> ...`.
  `dispatch = manual`: Claude kullanıcıya tek satır verir; `auto`: kendisi çalıştırır. İlk projelerde manual.
- **Kontroller:** `make check FEATURE=<f>` = lint (Verilator + Vivado) + simülasyon (xsim; hızlı
  koşu için Verilator veya iverilog) + OOC timing + kilitli dosyalar. İsteğe bağlı: `make trace`.
  Eksik araç PASS sayılmaz.
- **Türetilmiş gereksinim:** spec'te olmayan davranış `DERIVED-nnn` olarak listelenir; Claude (L4'te
  kullanıcı) kabul eder veya reddeder. Zayıf modellerin "kendi tasarımını uydurmasını" bu yakalar.
- **Bağımsızlık:** TB spec'ten yazılır; L3'te kabul TB'si Claude'undur ve kilitlidir.
- **Kayıt:** her commit'e script `Model/Role/Task` satırı ekler (`flow/git/commit.sh`); L2–L4'te
  `tracking/model_scorecard.md`'ye görev başına bir satır (başlangıç/bitiş zamanıyla).
- **İnceleme derinliği:** L1 Opus inceler; L2 Sonnet özelliğin dosyalarını ve kontrol çıktısını,
  `hard`'da tümünü; L3 Claude kodu okumaz (kabul testleri ölçüttür); L4 DeepSeek inceler.

## 8. LLM wiki (seçenek)

Karpathy'nin "LLM Wiki" kalıbı: kaynaklar bir kez okunur, LLM'in yönettiği küçük bağlantılı
sayfalara derlenir; sorular sayfalardan cevaplanır. İnsan dokümanından ayrıdır (İngilizce, LLM için).
Çekirdeği codemap'tir: `make codemap` modül kartlarının arayüz bölümünü koddan üretir, model yalnızca
amaç/not yazar. Ücretsiz modelin derlediği bilgi `status: unverified` taşır. Kurallar `llm/wiki/SCHEMA.md`.

## 9. Araçlar ve sürümler

- Claude Code (Pro; limit çabuk dolar → Opus az, oturumlar kısa), opencode (ücretsiz modeller),
  VS Code (editör + terminal; yapay zekâ eklentisi şimdilik yok). Kurulum: `SETUP.md`.
- **Tek talimat kaynağı `AGENTS.md`** (opencode okur); `CLAUDE.md` = `@AGENTS.md` + Claude ekleri.
- **AMD Ross projeye sabitlenir:** skill'ler `third_party/ross-ai-assistant` submodule'ünden
  `.claude/skills/`'e bağlanır (opencode da okur); Vivado MCP sunucusu makinede sürüm sürüm yan yana
  durur, proje kendi sürümünün yolunu kullanır. Global skill kurulumu yapılmaz; VS Code Ross
  eklentisi MCP sunucusuyla birlikte kullanılmaz.
- **Sürüm kuralı:** Vivado, Ross, Verilator, model ve kit sürümleri `project.toml`'da sabittir.
  Bir iş ortasında değişmez; yükseltme ara teslimden sonra, tam kontrol ve bir satır karar kaydıyla.
- **Bağlam disiplini:** PDF ve uzun incelemeler ana oturuma ham girmez (önce alt ajan/ücretsiz model
  özetler); log'lar `build/`'de kalır; AMD belgeleri `amd-doc-search` ile sorgulanır.

## 10. Kit bakımı

- Aylık: Ross sürüm notları; yeni sürüm `kit_config.toml`'a (yalnızca yeni projeler etkilenir),
  yararlı yeni skill'ler ilgili rol metnine.
- Her projeden sonra: model karnesi ve dersler kitteki rol tablosuna ve şablonlara.
- Kit bir git reposudur; projeler hangi kit sürümüyle kurulduğunu `project.toml`'da tutar.

## 11. Başlarken (bu kiti alan Claude için)

1. Kiti okuduğunu tek cümleyle teyit et.
2. Kullanıcıdan işi anlatmasını iste; yalnızca ne istediğini sor (en fazla 5 kısa soru).
3. Profili tek cümle gerekçeyle öner, onay al; §5.1'i uygula.
4. Teknik kararları sen ver, kısaca söyle; kullanıcıyı yalnızca 3 onay noktasında durdur.
5. Türkçe ve kısa konuş; proje dosyaları İngilizce (README hariç).
