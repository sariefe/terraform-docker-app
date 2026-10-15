# Terraform + Docker: Nginx, Flask, PostgreSQL

Terraform ile Docker üzerinde çok katmanlı bir uygulama ortamı kuran öğrenme projesi. Nginx isteği Flask uygulamasına iletir, Flask ziyaret sayısını PostgreSQL'de saklar. Tüm altyapı kodla tanımlanır ve tek komutla kurulup silinebilir.

## Mimari

```
Tarayıcı / curl
      │  :8080
      ▼
┌───────────┐    ┌───────────┐    ┌────────────┐
│   Nginx   │───▶│   Flask   │───▶│ PostgreSQL │
│ (web)     │    │ (app:5000)│    │ (db:5432)  │
└───────────┘    └───────────┘    └─────┬──────┘
      └──────── Docker ağı ─────────────┘
                                   docker_volume
                                   (kalıcı veri)
```

- Yalnızca Nginx host'a port açar (`8080`). Flask ve PostgreSQL sadece Docker ağı içinden erişilebilir.
- PostgreSQL verisi bir Docker volume'unda tutulur, container silinse bile korunur.
- Flask imajı Terraform tarafından `app/` klasöründen derlenir; kaynak dosyalar değişince imaj yeniden oluşturulur.

## Gereksinimler

- Docker (servis çalışıyor ve kullanıcı `docker` grubunda olmalı)
- Terraform >= 1.5 (ya da OpenTofu)

## Kullanım

```bash
# 1. Şifre dosyasını oluşturun ve değeri değiştirin
cp terraform.tfvars.example terraform.tfvars

# 2. Kurulum
terraform init
terraform plan
terraform apply

# 3. Test: her istekte sayaç artar
curl http://localhost:8080
curl http://localhost:8080

# 4. Silme
terraform destroy
```

> **Uyarı:** `terraform destroy` PostgreSQL volume'unu da siler, veritabanındaki veriler kaybolur.

## Değişkenler

| Değişken | Varsayılan | Açıklama |
|---|---|---|
| `project_name` | `tflab` | Kaynak adlarında kullanılan önek |
| `external_port` | `8080` | Host üzerinde yayınlanan port |
| `db_name` | `appdb` | Veritabanı adı |
| `db_user` | `appuser` | Veritabanı kullanıcısı |
| `db_password` | (yok) | Veritabanı şifresi, `terraform.tfvars` içinde verilir (`sensitive`) |

Örnek: `terraform apply -var="external_port=9090"`

## Proje yapısı

```
.
├── main.tf                    # ağ, volume, imajlar ve container'lar
├── variables.tf               # girdi değişkenleri
├── outputs.tf                 # erişim adresi ve container adları
├── terraform.tfvars.example   # şifre dosyası şablonu
├── app/
│   ├── app.py                 # Flask uygulaması
│   ├── requirements.txt
│   └── Dockerfile
└── nginx/
    └── default.conf           # reverse proxy ayarı
```

## Deneyler

1. **Kalıcılık:** `docker rm -f tflab-db` ile veritabanı container'ını silin, `terraform apply` çalıştırın. Sayaç kaldığı yerden devam eder.
2. **İmaj yenileme:** `app/app.py` içindeki bir değeri değiştirip `terraform apply` çalıştırın. İmaj yeniden derlenir.
3. **Drift:** Bir container'ı elle silip `terraform plan` çalıştırın. Terraform farkı algılar.
4. **State:** `terraform state list` ve `terraform state show docker_container.app` komutlarını inceleyin.

## Güvenlik notları

- `terraform.tfvars` ve `terraform.tfstate` dosyaları `.gitignore` ile dışarıda tutulur. State dosyası şifreyi **düz metin** olarak içerir, asla commit edilmemelidir.
- Bu proje öğrenme amaçlıdır. Gerçek bir ortamda remote backend, secret yönetimi ve TLS kullanılmalıdır.

## Kullanılan araçlar

Terraform, `kreuzwerker/docker` provider'ı, Docker, Nginx, Flask, Gunicorn, PostgreSQL 16
