# Makine kurulumu (Ubuntu, bir kez)

Bu rehber iş bilgisayarını bir kez hazırlar. Sonunda `tools/check_machine.sh` `MACHINE_RESULT: PASS`
yazmalıdır. **PİLOT** işaretli adımlar ilk kurulumda doğrulanacak; komut farklı çıkarsa bu dosya güncellenir.

Sıra: 1 temel paketler → 2 Vivado/Vitis → 3 GitHub ve kit → 4 Claude Code → 5 opencode ve modeller →
6 AMD Ross → 7 VS Code → 8 kontrol. 9 Zynq ve 10 iç ağ gerektiğinde.

## 1. Temel paketler

```bash
sudo apt update
sudo apt install -y git make python3 python3-pip curl gnupg build-essential \
                    verilator iverilog gtkwave
python3 -V          # 3.11+ olmalı; değilse: pip install --user tomli
verilator --version # Ubuntu 24.04: 5.020 (yeterli). Sürüm kit_config.toml'a yazılır.
```

## 2. Vivado ve Vitis

- AMD Unified Installer ile Vivado (ve Zynq/HLS gerekiyorsa Vitis) kurulur, örn. `/tools/Xilinx/`.
  Ubuntu sürümünün AMD'nin desteklediği listede olduğunu sürüm notlarından kontrol et (UG973).
- Her terminalde araçların bulunması için `~/.bashrc`'ye:
  ```bash
  source /tools/Xilinx/Vivado/<sürüm>/settings64.sh
  ```
- Eksik kütüphane hatası çıkarsa (ör. `libtinfo.so.5`) AMD'nin o sürüm için verdiği çözüm uygulanır. **PİLOT**
- Kart ile çalışılacaksa kablo sürücüleri (`install_drivers`) ayrıca kurulur; şimdilik gerekmiyor.

## 3. GitHub ve kit

```bash
git config --global user.name "<ad soyad>"
git config --global user.email "<e-posta>"
ssh-keygen -t ed25519 -C "<e-posta>"        # ~/.ssh/id_ed25519.pub içeriğini GitHub > Settings > SSH keys'e ekle
ssh -T git@github.com                        # "successfully authenticated" görmelisin
git clone git@github.com:teoaks09/FPGA-Development-Method.git ~/fpga-method
```
Claude Code ve opencode GitHub'a ayrı bir bağlantıyla değil, terminaldeki `git` ile erişir; SSH
anahtarı ikisi için de yeterlidir. İstersen `gh` (GitHub CLI) da kurulabilir: `sudo apt install gh && gh auth login`.

## 4. Claude Code

Desktop uygulaması kurulu. Terminal sürümü (opencode'u çağırmak ve script'ler için):
```bash
curl -fsSL https://claude.ai/install.sh | bash
claude --version
claude doctor
```
İlk `claude` çalıştırmasında tarayıcıdan Pro hesabıyla giriş yapılır. Desktop uygulamasındaki Code
bölümü de aynı proje klasörüyle çalışır.

## 5. opencode ve ücretsiz modeller

```bash
curl -fsSL https://opencode.ai/install | bash      # PİLOT: resmi kurulum komutunu opencode.ai'den teyit et
opencode --version
```
**Kurum modelleri** `~/.config/opencode/opencode.json` içinde OpenAI uyumlu sağlayıcı olarak tanımlanır:
```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "corp": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Kurum",
      "options": { "baseURL": "https://<kurum-sunucusu>/v1" },
      "models": {
        "general": { "name": "Qwen3.8 Flash Next" },
        "code":    { "name": "DeepSeek Flash v4.1" }
      }
    }
  }
}
```
Anahtar: `opencode auth login` → **Other** → sağlayıcı adı `corp` → anahtar. Yeni ücretsiz modeller
(opencode'un kendi ücretsiz modelleri dahil) aynı şekilde eklenir.

Kontrol:
```bash
opencode models                                   # id'leri buradan kit_config.toml [models]'a kopyala
opencode run -m corp/general "Merhaba, tek cümle cevap ver."
```
**Claude'dan çağırma testi** (bir Claude Code oturumunda Claude'a çalıştırt):
`opencode run --auto -m corp/code "pwd ve ls çıktısını yaz"`. Çıktı gelmeli ve `opencode` loglarında
modelin `corp/code` olduğu görülmeli. `--auto`, açıkça yasaklanmamış izinleri onaylar; ajan
dosyalarındaki yol izinleri yine geçerlidir. **PİLOT**

## 6. AMD Ross

Ross iki parçadır: makinedeki **Vivado MCP sunucusu** (sürüm sürüm yan yana) ve projeye sabitlenen
**skill'ler** (projede submodule; global kurulmaz).

1. AMD Ross indirme sayfasından `vivado-mcp-server-linux-amd64-<sürüm>` indir:
   ```bash
   mkdir -p ~/tools/ross/<sürüm> && mv vivado-mcp-server-linux-amd64-<sürüm> ~/tools/ross/<sürüm>/
   chmod +x ~/tools/ross/<sürüm>/vivado-mcp-server-linux-amd64-<sürüm>
   ```
2. Belge arama (`amd-doc-search`): https://ross.amd.com/chat#setup adresindeki yapılandırma URL'sini
   `kit_config.toml` → `amd_doc_search_url`'e yaz. İç ağ için yerel bilgi tabanı (§10).
3. **Ross VS Code eklentisini kurma** ve skill'leri `~/.claude/skills/`'e kurma: Ross belgesine göre
   MCP sunucusu ile eklenti birlikte kullanılmaz, skill'ler de iki kez yüklenir.
4. Test (bir proje kurulduktan sonra, proje klasöründe): `flow/tools/ross_setup.sh`, sonra Claude
   Code'da `/mcp` ile `vivado` sunucusunun bağlı olduğunu gör ve "Vivado MCP ile Vivado sürümünü
   söyle" de. opencode'da aynı soruyu sor (`opencode.json` aynı sunucuyu gösterir). **PİLOT**

## 7. VS Code

```bash
sudo snap install code --classic
```
Editör ve terminal olarak kullanılır; Claude Code ve opencode VS Code terminalinde çalışır.
SystemVerilog sözdizimi için bir eklenti yeterli (ör. "Verilog-HDL/SystemVerilog"). Yapay zekâ
eklentisi şimdilik kurulmaz.

## 8. Kit ayarı ve kontrol

`~/fpga-method/kit_config.toml`: Vivado/Vitis yolları, Ross sürümü ve MCP klasörü, model id'leri,
`amd_doc_search_url`, IP vendor adı. Sonra:
```bash
~/fpga-method/tools/check_machine.sh          # MACHINE_RESULT: PASS
```
Deneme projesi:
```bash
python3 ~/fpga-method/tools/new_project.py --name deneme --dest ~/work/deneme --team L1 \
    --prefix dn --part <parça> --features blink:simple --git
cd ~/work/deneme && flow/tools/ross_setup.sh && make env-check
```

## 9. Zynq PS (nadiren)

- Vitis, Unified Installer içinde gelir (§2). Bare-metal için yeterli.
- PetaLinux ayrı kurulur; yalnızca gerektiğinde. Kurulduğunda yolu `kit_config.toml` → `petalinux_path`.

## 10. İç ağ (Claude ve internet yok)

İç ağ makinesine kurulur: §1, §2, §5 (yalnızca kurum modelleri), §6.1 (MCP sunucusu) ve Ross'un
**yerel bilgi tabanı** (AMD indirme sayfasındaki "Local Knowledge Base" paketi, kurulumu Ross
reposundaki `docs/local-kb`). Claude Code ve GitHub yoktur; projeler fiilen L4 gibi yürür.

Projeyi taşıma (dışarıda):
```bash
cd <proje>
git bundle create ../proje.bundle --all
git -C third_party/ross-ai-assistant bundle create ../../../ross.bundle --all
```
İç ağda:
```bash
git clone proje.bundle proje && cd proje
git config submodule.third_party/ross-ai-assistant.url "$(realpath ../ross.bundle)"
git submodule update --init
flow/tools/ross_setup.sh        # skill bağlantıları; ardından make env-check
```
Geri getirme aynı yolla (`git bundle`), dışarıda `git pull ../proje.bundle`.
