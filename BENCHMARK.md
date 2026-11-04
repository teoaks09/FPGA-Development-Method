# Benchmark: aynı iş, dört ekip seviyesi

Amaç: L1–L4'ü aynı iş üzerinde ölçüp rol/model tablosunu (`agents/roles.toml`) veriyle ayarlamak.
Dış incelemelerden sonra, kitin o sürümüyle yapılır; kit sürümü sonuç tablosuna yazılır.

## İş
AXI4-Lite arayüzlü UART: 8N1, baud bölücü register'ı, TX/RX FIFO (XPM), durum ve hata
register'ları (overrun, framing), kesme çıkışı. Teslim: `code` + `ip`. Hedef: 100 MHz, Artix-7.
Aynı `docs/requirements.md` dört koşuda da kullanılır (kurulum oturumunda bir kez yazılır, kopyalanır).

## Koşular
| Koşu | Profil | Yürüten |
|---|---|---|
| B1 | L1 × {code, ip} | Claude Code |
| B2 | L2 × {code, ip} | Claude Code + opencode (manual dispatch) |
| B3 | L3 × {code, ip} | Claude Code + opencode |
| B4 | L4 × {code, ip} | opencode (start prompt) |

Kurallar: her koşu ayrı klasörde; aynı gereksinim dosyası; kullanıcı yalnızca 3 onay noktasında
müdahale eder (müdahaleler not edilir); koşu, `make check` PASS + `make ip` PASS + README ile biter
veya 4 saatlik aktif çalışma sınırında durdurulur.

## Kalibrasyon (TB'yi kim yazmalı)
B2'de aynı özelliğin testbench'i hem DeepSeek hem Qwen'e ayrı ayrı yazdırılır (ikisi de RTL'i
görmez). Ölçü: bağımsız TB'nin bulduğu ve bu TB'nin kaçırdığı hatalar, bilerek eklenen 3 hatadan
kaçının yakalandığı, süre. Sonuç `roles.toml` verification satırını belirler (L2–L4).

## Ölçülenler
| Ölçü | Nasıl |
|---|---|
| Duvar saati süresi (toplam ve aşama aşama: spec, RTL, TB, check, IP, README) | `tracking/status.md` "Done" satırlarındaki saatler + git commit zamanları |
| Kullanıcının aktif süresi ve müdahale sayısı | Kullanıcı not eder |
| Claude kullanımı | Oturum başı/sonu `/usage` (veya `/cost`) değeri; Pro limit yüzdesi |
| Ücretsiz model çağrı sayısı ve süresi | `tracking/model_scorecard.md` (başlangıç/bitiş) |
| İlk denemede geçme, deneme sayısı, yükseltme | scorecard |
| Türetilmiş gereksinim sayısı | sonuç kartları |
| Kalite | Bağımsız testbench (kullanıcının mevcut testbench'i + kitin dışında yazılan bir referans TB) ile bulunan hatalar; lint uyarıları; OOC WNS; kaynak kullanımı |
| Kod hijyeni | reviewer bulguları + kullanıcı kontrolü (CDC, reset, sayaç genişliği) |

## Sonuç tablosu
| Koşu | Kit | Toplam süre | Kullanıcı süresi | Claude kullanımı | Hata (bağımsız TB) | WNS | Not |
|---|---|---|---|---|---|---|---|

## Sonra
Sonuçlara göre: rol → model eşlemesi, efor, deneme limiti, şablonlar. Büyük fark çıkarsa
seviye tanımlarının kendisi gözden geçirilir.
