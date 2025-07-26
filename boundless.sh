#!/bin/bash

# Fungsi menu utama
function menu_utama() {
    while true; do
        clear
        echo "================================================================"
        echo "Skrip ini  Gratis dan open source — JANGAN PERNAH MEMBAYAR"
        echo "================================================================"
        echo "Tekan Ctrl + C untuk keluar dari skrip"
        echo "Silakan pilih operasi yang ingin dilakukan:"
        echo "1) Instal dan deploy node"
        echo "2) Lihat saldo staking"
        echo "3) Lihat log broker"
        echo "4) Hapus node"
        echo "q) Keluar dari skrip"
        echo "================================================================"
        read -p "Masukkan pilihan Anda [1/2/3/4/q]: " pilihan
        case $pilihan in
            1) pasang_node ;;
            2) cek_saldo_stake ;;
            3) lihat_log_broker ;;
            4) hapus_node ;;
            q|Q)
                echo "Terima kasih sudah menggunakan, sampai jumpa!"
                exit 0
                ;;
            *)
                echo "Pilihan tidak valid, silakan coba lagi..."
                sleep 2
                ;;
        esac
    done
}

# Fungsi untuk instal dan deploy node
function pasang_node() {
    clear
    echo "Memulai instalasi dan deploy node..."

    if cargo install --list | grep -q 'cargo-risczero'; then
    echo "cargo-risczero sudah terinstal."
else
    cargo install cargo-risczero
    rzup install cargo-risczero
    if [ $? -ne 0 ]; then
        echo "Gagal instal cargo-risczero."
        exit 1
    fi
fi  # ⬅️ ini yang lupa kamu tulis

    echo "Memeriksa apakah Docker sudah terinstal..."
    if ! command -v docker &> /dev/null; then
        echo "Docker belum ditemukan, menginstal Docker..."
        apt-get update
        apt-get install -y ca-certificates curl gnupg
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        usermod -aG docker $SUDO_USER
        echo "Docker berhasil diinstal. Silakan logout dan login ulang agar grup Docker aktif."
    fi

    echo "Memeriksa dukungan NVIDIA Docker..."
    if ! command -v nvidia-docker &> /dev/null; then
        echo "Menginstal NVIDIA Container Toolkit..."
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
        curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
        apt-get update
        apt-get install -y nvidia-container-toolkit
        systemctl restart docker
        echo "NVIDIA Container Toolkit berhasil diinstal"
    fi

    echo "Memeriksa apakah screen sudah terinstal..."
    if ! command -v screen &> /dev/null; then
        echo "Menginstal screen..."
        apt-get update
        apt-get install -y screen
        if [ $? -ne 0 ]; then
            echo "Gagal menginstal screen. Silakan instal manual."
            exit 1
        fi
        echo "screen berhasil diinstal"
    fi

if ! command -v just &> /dev/null; then
    echo "Menginstal just..."
    curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
    if [ $? -ne 0 ]; then
        echo "Gagal menginstal just. Silakan instal manual."
        exit 1
    fi
    echo "just berhasil diinstal"
fi
echo "just berhasil diinstal"
source ~/.bashrc


    echo "Memeriksa dependensi kalkulator bc..."
    if ! command -v bc &> /dev/null; then
        echo "Menginstal bc..."
        apt-get update
        apt-get install -y bc
        if [ $? -ne 0 ]; then
            echo "Gagal menginstal bc. Silakan instal manual."
            exit 1
        fi
        echo "bc berhasil diinstal"
    fi

    echo "Mulai mengkloning repositori..."
    if [ -d "boundless" ]; then
        echo "Direktori 'boundless' sudah ada, menghapus untuk kloning ulang..."
        rm -rf boundless
    fi

    git clone https://github.com/boundless-xyz/boundless
    if [ $? -ne 0 ]; then
        echo "Gagal mengkloning repositori. Periksa koneksi internet atau URL repo."
        exit 1
    fi

    echo "Direktori kerja saat ini: $(pwd)"
    echo "Memeriksa direktori boundless..."
    if [ ! -d "boundless" ]; then
        echo "Error: Direktori boundless tidak ditemukan setelah kloning"
        echo "Isi direktori saat ini:"
        ls -la
        exit 1
    fi

    echo "Berhasil menemukan direktori boundless. Berpindah direktori..."
    cd boundless
    echo "Sekarang di direktori: $(pwd)"

    echo "Checkout ke branch release-0.10..."
    git checkout release-0.10
    if [ $? -ne 0 ]; then
        echo "Gagal beralih ke branch release-0.10"
        exit 1
    fi
    echo "Menginstal Rust dan toolchain yang dibutuhkan..."
    echo "Menginstal rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    if [ $? -ne 0 ]; then
        echo "Gagal instalasi rustup. Periksa koneksi internet atau instal manual."
        exit 1
    fi
    echo "rustup berhasil diinstal"

    echo "Memperbarui rustup..."
    rustup update
    if [ $? -ne 0 ]; then
        echo "Gagal memperbarui rustup."
        exit 1
    fi
    echo "rustup berhasil diperbarui"

    echo "Menginstal toolchain Rust (cargo)..."
    apt-get update
    apt-get install -y cargo
    if [ $? -ne 0 ]; then
        echo "Gagal instal cargo. Silakan instal manual."
        exit 1
    fi
    echo "cargo berhasil diinstal"

    echo "Memverifikasi cargo..."
    cargo --version
    if [ $? -ne 0 ]; then
        echo "Verifikasi cargo gagal. Instalasi tidak berhasil."
        exit 1
    fi
    echo "Verifikasi cargo berhasil"

    echo "Menginstal rzup..."
    curl -L https://risczero.com/install | bash
    source ~/.bashrc
    export PATH="$HOME/.risc0/bin:$PATH"
    if [ $? -ne 0 ]; then
        echo "Gagal instal rzup."
        exit 1
    fi
    echo "rzup berhasil diinstal"

echo "rzup berhasil diinstal"
source ~/.bashrc  # ⬅️ Segera aktifkan PATH setelah instalasi

echo "Memverifikasi rzup..."
rzup --version
if [ $? -ne 0 ]; then
    echo "Verifikasi rzup gagal."
    exit 1
fi
echo "Verifikasi rzup berhasil"
echo "Menginstal toolchain Rust untuk RISC Zero..."
if rzup toolchain list | grep -q 'risc0'; then
    echo "Toolchain RISC Zero sudah ada, dilewati."
else
    rzup install rust
    if [ $? -ne 0 ]; then
        echo "Gagal instal toolchain RISC Zero."
        echo "Jika muncul error GitHub API rate limit, buat token di https://github.com/settings/tokens dan jalankan: export GITHUB_TOKEN=tokenmu"
        exit 1
    fi
fi
echo "Toolchain RISC Zero berhasil diinstal"


    echo "Menginstal cargo-risczero..."
    if cargo install --list | grep -q 'cargo-risczero'; then
        echo "cargo-risczero sudah terinstal."
    else
        cargo install cargo-risczero
        rzup install cargo-risczero
        if [ $? -ne 0 ]; then
            echo "Gagal instal cargo-risczero."
            exit 1
        fi
    fi
    echo "cargo-risczero berhasil diinstal"
    echo "Memperbarui rustup sekali lagi..."
    rustup update
    if [ $? -ne 0 ]; then
        echo "Gagal memperbarui rustup."
        exit 1
    fi
    echo "rustup berhasil diperbarui"

    echo "Menginstal bento-client..."
    if cargo install --list | grep -q 'bento_cli'; then
        echo "bento-client sudah terinstal, dilewati."
    else
        cargo install --git https://github.com/risc0/risc0 bento-client --bin bento_cli
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
        source ~/.bashrc
        if [ $? -ne 0 ]; then
            echo "Gagal instal bento-client."
            exit 1
        fi
    fi
    echo "bento-client berhasil diinstal"

    echo "Verifikasi bento-client..."
    bento_cli --version
    if [ $? -ne 0 ]; then
        echo "Verifikasi bento-client gagal."
        exit 1
    fi
    echo "bento-client diverifikasi!"

    echo "Menjalankan skrip setup.sh..."
    chmod +x scripts/setup.sh
    ./scripts/setup.sh || echo "setup.sh gagal dijalankan, melanjutkan..."

    echo "Menginstal boundless-cli..."
    if cargo install --list | grep -q 'boundless-cli'; then
        echo "boundless-cli sudah terinstal, dilewati."
    else
        cargo install --locked boundless-cli
        export PATH=$PATH:/root/.cargo/bin
        source ~/.bashrc
        if [ $? -ne 0 ]; then
            echo "Gagal instal boundless-cli."
            exit 1
        fi
    fi
    echo "boundless-cli berhasil diinstal"

echo "boundless-cli berhasil diinstal"
source ~/.bashrc  # ⬅️ TARUH DI SINI, setelah berhasil instal, sebelum diverifikasi

echo "Verifikasi boundless-cli..."
boundless -h
if [ $? -ne 0 ]; then
    echo "Verifikasi boundless-cli gagal."
    exit 1
fi
echo "boundless-cli diverifikasi!"


    echo "SEMUA dependensi telah berhasil diinstal!"
    echo "Silakan logout dan login ulang agar grup Docker aktif."

    # Mengecek total memori dan CPU
    MEM_TOTAL=$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)
    CPU_TOTAL=$(nproc)

    echo "----------------------------------------"
    echo "Total RAM terdeteksi: ${MEM_TOTAL} GB"
    echo "Total CPU core terdeteksi: ${CPU_TOTAL}"
    echo "Silakan masukkan jumlah memori & core CPU yang akan dialokasikan untuk node."
    echo "----------------------------------------"

    # Input dari user
    while true; do
        read -p "Masukkan alokasi RAM untuk node (dalam GB, max ${MEM_TOTAL}): " MEM_INPUT
        if [[ "$MEM_INPUT" =~ ^[0-9]+$ ]] && [ "$MEM_INPUT" -le "$MEM_TOTAL" ] && [ "$MEM_INPUT" -ge 1 ]; then
            break
        else
            echo "Input tidak valid. Masukkan angka antara 1 hingga ${MEM_TOTAL}."
        fi
    done

    while true; do
        read -p "Masukkan jumlah core CPU untuk node (max ${CPU_TOTAL}): " CPU_INPUT
        if [[ "$CPU_INPUT" =~ ^[0-9]+$ ]] && [ "$CPU_INPUT" -le "$CPU_TOTAL" ] && [ "$CPU_INPUT" -ge 1 ]; then
            break
        else
            echo "Input tidak valid. Masukkan angka antara 1 hingga ${CPU_TOTAL}."
        fi
    done

    # Menyesuaikan compose.yml
    COMPOSE_FILE="compose.yml"
    if [ ! -f "$COMPOSE_FILE" ]; then
        COMPOSE_FILE="docker-compose.yml"
    fi

    if [ ! -f "$COMPOSE_FILE" ]; then
        echo "File compose.yml tidak ditemukan!"
    else
        sed -i "/x-exec-agent-common: &exec-agent-common/,/cpus:/s/mem_limit: .*/mem_limit: ${MEM_INPUT}G/" "$COMPOSE_FILE"
        sed -i "/x-exec-agent-common: &exec-agent-common/,/environment:/s/cpus: .*/cpus: ${CPU_INPUT}/" "$COMPOSE_FILE"
        echo "compose.yml telah diperbarui: mem_limit=${MEM_INPUT}G, cpus=${CPU_INPUT}"
    fi
    # Cek apakah sistem punya GPU NVIDIA
    if command -v nvidia-smi &> /dev/null; then
        GPU_MEM_TOTAL=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n1)
        GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)
        echo "----------------------------------------"
        echo "Terdeteksi GPU: $GPU_NAME"
        GPU_MEM_TOTAL_GB=$(( (GPU_MEM_TOTAL + 1023) / 1024 ))
        echo "GPU memiliki memori maksimal ${GPU_MEM_TOTAL_GB} GB"
        echo "----------------------------------------"

        while true; do
            read -p "Masukkan alokasi memori GPU untuk gpu_prove_agent0 (dalam GB, maks ${GPU_MEM_TOTAL_GB}): " GPU_MEM_INPUT
            if [[ "$GPU_MEM_INPUT" =~ ^[0-9]+$ ]] && [ "$GPU_MEM_INPUT" -le "$GPU_MEM_TOTAL_GB" ] && [ "$GPU_MEM_INPUT" -ge 1 ]; then
                break
            else
                echo "Input tidak valid. Harus antara 1 sampai ${GPU_MEM_TOTAL_GB} GB"
            fi
        done

        GPU_CPU_TOTAL=$(nproc)
        while true; do
            read -p "Masukkan jumlah core CPU untuk gpu_prove_agent0 (maks ${GPU_CPU_TOTAL}): " GPU_CPU_INPUT
            if [[ "$GPU_CPU_INPUT" =~ ^[0-9]+$ ]] && [ "$GPU_CPU_INPUT" -le "$GPU_CPU_TOTAL" ] && [ "$GPU_CPU_INPUT" -ge 1 ]; then
                break
            else
                echo "Input tidak valid. Harus antara 1 sampai ${GPU_CPU_TOTAL}"
            fi
        done

        if [ ! -f "$COMPOSE_FILE" ]; then
            echo "compose.yml tidak ditemukan!"
        else
            sed -i "/gpu_prove_agent0:/,/cpus:/s/mem_limit: .*/mem_limit: ${GPU_MEM_INPUT}G/" "$COMPOSE_FILE"
            sed -i "/gpu_prove_agent0:/,/entrypoint:/s/cpus: .*/cpus: ${GPU_CPU_INPUT}/" "$COMPOSE_FILE"
            echo "GPU konfigurasi berhasil diperbarui di compose.yml"
        fi
    else
        echo "GPU NVIDIA tidak terdeteksi, melewati konfigurasi GPU."
    fi

    echo "============================================"
    echo "Silakan masukkan PRIVATE_KEY dan RPC_URL Anda"
    echo "Gunakan Base network dari Alchemy"
    echo "============================================"

    read -p "Masukkan PRIVATE_KEY Anda: " PRIVATE_KEY
    read -p "Masukkan RPC_URL untuk jaringan Base: " RPC_URL

    if [[ "$RPC_URL" != *"base"* ]]; then
        echo "Peringatan: RPC_URL Anda tampaknya bukan jaringan Base."
        read -p "Apakah Anda yakin ingin lanjut? (y/n): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "Dibatalkan. Silakan jalankan ulang skrip."
            exit 1
        fi
    fi

    if [ -z "$PRIVATE_KEY" ] || [ -z "$RPC_URL" ]; then
        echo "PRIVATE_KEY atau RPC_URL kosong. Skrip dihentikan."
        exit 1
    fi

    sed -i '/^export PRIVATE_KEY=/d' .env.base 2>/dev/null
    sed -i '/^export RPC_URL=/d' .env.base 2>/dev/null

    echo "export PRIVATE_KEY=$PRIVATE_KEY" >> .env.base
    echo "export RPC_URL=$RPC_URL" >> .env.base

    if grep -q "export PRIVATE_KEY=$PRIVATE_KEY" .env.base && grep -q "export RPC_URL=$RPC_URL" .env.base; then
        echo ".env.base berhasil ditulis."
        source .env.base
        if [ -z "$PRIVATE_KEY" ] || [ -z "$RPC_URL" ]; then
            echo "Gagal memuat variabel lingkungan!"
            exit 1
        fi
    else
        echo "Gagal menulis ke .env.base"
        exit 1
    fi

    echo "Lingkungan testnet telah disiapkan via .env.base"

    echo "----------------------------------------"
    echo "Apakah Anda ingin menyetor USDC ke akun staking?"
    read -p "Lanjut setoran USDC? (y/n): " NEED_DEPOSIT

    if [[ "$NEED_DEPOSIT" == "y" || "$NEED_DEPOSIT" == "Y" ]]; then
        while true; do
            read -p "Masukkan jumlah USDC untuk disetor (minimal 5): " USDC_AMOUNT
            if [[ "$USDC_AMOUNT" =~ ^[0-9]+(\.[0-9]+)?$ ]] && awk "BEGIN{exit !($USDC_AMOUNT >= 5)}"; then
                break
            else
                echo "Input tidak valid. Masukkan angka minimal 5"
            fi
        done

        boundless account deposit-stake "$USDC_AMOUNT"
        if [ $? -ne 0 ]; then
            echo "Setoran gagal. Periksa saldo dan jaringan."
            exit 1
        fi
        echo "Setoran USDC berhasil!"
    else
        echo "Langkah setoran dilewati."
    fi

    echo "----------------------------------------"
    echo "Masukkan SEGMENT_SIZE untuk GPU:"
    echo "19: untuk 8GB, 20: untuk 16GB, 21: untuk 20GB, 22: untuk 40GB"
    while true; do
        read -p "SEGMENT_SIZE (19/20/21/22): " SEGMENT_SIZE
        if [[ "$SEGMENT_SIZE" =~ ^(19|20|21|22)$ ]]; then
            break
        else
            echo "Input tidak valid. Harus 19, 20, 21, atau 22."
        fi
    done

    if [ -f "$COMPOSE_FILE" ]; then
        sed -i "/x-exec-agent-common: &exec-agent-common/,/entrypoint:/s|entrypoint: /app/agent -t exec --segment-po2 \\${SEGMENT_SIZE:-[0-9][0-9]}|entrypoint: /app/agent -t exec --segment-po2 $SEGMENT_SIZE|" "$COMPOSE_FILE"
        echo "SEGMENT_SIZE berhasil diperbarui di compose.yml"
    fi

  just broker > broker.log 2>&1 &
  echo "Broker dijalankan di background (log disimpan di broker.log)"


    echo "🎉 Instalasi selesai!"
    read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali ke menu utama..."
    echo
}

