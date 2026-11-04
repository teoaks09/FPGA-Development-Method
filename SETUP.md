# Makine kurulumu (Ubuntu 22.04, bir kez)

Bu rehber iş bilgisayarını bir kez hazırlar; sonunda `tools/check_machine.sh` `MACHINE_RESULT: PASS`
yazmalıdır. Araç sürümleri sabitlenmez: projeler makinede ne kuruluysa onu kullanır, araçlar ara sıra
elle güncellenir (§11).

Yerleşim: araçlar `/opt/<araç>/<sürüm>` + `/opt/<araç>/current` bağlantısı; Xilinx ve Ross büyük
diskte (`/mnt/E/Xilinx`); kit `~/WorkspaceAI/fpga-method`, projeler `~/WorkspaceAI/<repo_adı>`,
denemeler `~/WorkspaceAI/_sandbox`.

## 1. Temel paketler

```bash
sudo apt update
sudo apt install -y git make python3 python3-pip curl build-essential gtkwave \
    autoconf flex bison gperf help2man libfl-dev zlib1g-dev ccache
pip install --user tomli        # Python 3.10 (Ubuntu 22.04) için gerekli
```

## 2. Verilator ve Icarus Verilog (kaynaktan, /opt altına)

Ubuntu 22.04 paketleri eski (Verilator 4, iverilog 11); kaynaktan derlenir:
```bash
git clone https://github.com/verilator/verilator && cd verilator && git checkout v<sürüm>
autoconf && ./configure --prefix=/opt/verilator/v<sürüm> && make -j$(nproc) && sudo make install
sudo ln -sfn /opt/verilator/v<sürüm> /opt/verilator/current
# iverilog aynı şekilde: github.com/steveicarus/iverilog, tag v12_0 -> /opt/iverilog/v12_0, current
```
`~/.bashrc`: `export PATH=/opt/verilator/current/bin:/opt/iverilog/current/bin:$PATH`

## 3. Vivado ve Vitis

AMD Unified Installer ile büyük diske (örn. `/mnt/E/Xilinx/<sürüm>`). `~/.bashrc`'ye:
```bash
source /mnt/E/Xilinx/<sürüm>/Vivado/settings64.sh
```
Kit Vivado'yu PATH'ten bulur; yol hiçbir yere yazılmaz. Yeni sürüm kurulunca yalnızca bu satır değişir.

## 4. GitHub ve kit

```bash
git config --global user.name "<kullanıcı>"; git config --global user.email "<e-posta>"
ssh-keygen -t ed25519 -C "<e-posta>"     # .pub içeriği: GitHub > Settings > SSH and GPG keys
```
Kurum ağı 22 numaralı portu kapatıyorsa SSH 443'ten geçer (`~/.ssh/config`):
```
Host github.com
  HostName ssh.github.com
  Port 443
  User git
```
```bash
ssh -T git@github.com                    # "successfully authenticated"
git clone git@github.com:teoaks09/FPGA-Development-Method.git ~/WorkspaceAI/fpga-method
cd ~/WorkspaceAI/fpga-method && cp kit_config.example.toml kit_config.toml   # sonra düzenle
```

## 5. Claude Code

```bash
curl -fsSL https://claude.ai/install.sh | bash && claude --version
```
İlk çalıştırmada Pro hesabıyla giriş. `claude -p "<prompt>" --allowedTools "..."`: prompt
`--allowedTools`'tan önce yazılır (liste sonrakileri yutar).

## 6. AMD Ross (makineye bir kez, global)

Ross üç parçadır, hepsi `<ross_dir>` (örn. `/mnt/E/Xilinx/ross`) altında:
1. **Vivado MCP sunucusu**: AMD indirme sayfasındaki ikili → `<ross_dir>/vivado-mcp-server`
   (`chmod +x`). Claude Code: `claude mcp add -s user vivado-mcp -- <ross_dir>/vivado-mcp-server --stdio-bridge`.
2. **Belge arama** `amd-doc-search`: iç ağda Ross yerel bilgi tabanı (`http://127.0.0.1:8080/mcp/doc-search`),
   kurulumu Ross reposundaki `docs/local-kb`. Claude Code: `claude mcp add -s user -t http amd-doc-search <url>`.
3. **Skill'ler**: `git clone https://github.com/Xilinx/ross-ai-assistant <ross_dir>/ross-ai-assistant`.
   Claude Code'a plugin olarak (Ross belgesindeki marketplace komutları, user scope); opencode'a
   `tools/update_ross.sh` ile `~/.config/opencode/skills/` altına bağlantı.

opencode (`~/.config/opencode/opencode.jsonc`):
```jsonc
"mcp": {
  "vivado": { "type": "local", "command": ["<ross_dir>/vivado-mcp-server", "--stdio-bridge"], "enabled": true },
  "amd-doc-search": { "type": "remote", "url": "http://127.0.0.1:8080/mcp/doc-search", "enabled": true }
}
```
Kontrol: Claude Code'da `/mcp`; `opencode mcp list` (servis yeniden başladıktan sonraki ilk çağrı
"No MCP servers configured" diyebilir, ikinci çağrı doğrudur; iki istemci MCP'yi aynı anda
başlatırsa biri düşebilir: `pkill -f "opencode serve --service"` ve tekrar).
Ross VS Code eklentisi MCP sunucusuyla birlikte kurulmaz.

## 7. opencode ve ücretsiz modeller

Kurum modelleri `~/.config/opencode/opencode.jsonc` içinde OpenAI uyumlu sağlayıcıdır (örn. `bilgem`;
`general` = Qwen, `code` = DeepSeek). Efor seviyeleri modelin **variant**'larıdır (config'te
tanımlı); çağrı `-m bilgem/code#high`. Kitteki eşleme `kit_config.toml [models.variants]`.
```bash
opencode models                                    # id'ler → kit_config.toml [models]
opencode run --auto -m bilgem/code#none 'Sadece 2+2 sonucunu yaz.' < /dev/null
```
Sunucu mesai saatinde yavaşlayabilir (aynı çağrı 2 sn de 3 dk da sürebilir); Claude opencode'u
arka planda çalıştırıp bekler. Varsayılan variant'ı yüksek olan model basit işte de uzun düşünür.

## 8. VS Code

`sudo snap install code --classic`; editör ve terminal. SystemVerilog sözdizimi eklentisi yeterli.

## 9. Kontrol ve deneme projesi

```bash
~/WorkspaceAI/fpga-method/tools/check_machine.sh          # MACHINE_RESULT: PASS
python3 ~/WorkspaceAI/fpga-method/tools/new_project.py --name deneme --dest ~/WorkspaceAI/_sandbox/deneme \
    --team L1 --prefix dn --part <parça> --features blink:simple --git
cd ~/WorkspaceAI/_sandbox/deneme && make env-check
```

## 10. İç ağ (Claude ve internet yok)

İç ağ makinesine §1–3, §6 (MCP sunucusu, yerel bilgi tabanı, skill klonu) ve §7 (yalnızca kurum
modelleri) kurulur. Claude Code ve GitHub yoktur; projeler fiilen L4 gibi yürür. Taşıma:
```bash
git bundle create ../proje.bundle --all            # dışarıda
git clone proje.bundle proje                       # içeride; geri getirme: git pull ../proje.bundle
```
Ross skill klonu da aynı yolla (`git bundle`) taşınır ve güncellenir.

## 11. Güncelleme (ara sıra, elle)

- Ross skill'leri: `tools/update_ross.sh` (git pull + opencode bağlantıları + Claude plugin), sonra
  Claude Code ve opencode yeniden başlatılır.
- Ross MCP sunucusu / bilgi tabanı: AMD sayfasından yenisi indirilip `<ross_dir>`'deki dosya değiştirilir.
- Vivado: yeni sürüm kurulur, `~/.bashrc`'deki `settings64.sh` satırı değişir.
- Verilator / iverilog: yeni sürüm `/opt/<araç>/<sürüm>`'e derlenir, `current` bağlantısı taşınır.
- Güncellemeden sonra açık projelerde `make check` bir kez çalıştırılır; fark çıkarsa
  `docs/decisions.md`'ye bir satır.
