# 🖐️ HighFive - Öğrenci Evi Yönetim Asistanı

Öğrenci evlerinde ev arkadaşları arasında adil görev dağılımı (bulaşık, çöp, temizlik vb.), eve gelen misafirlerin takibi ve ortak yaşam kurallarını kolaylaştırmak için **SwiftUI**, **Clean Architecture** ve **MVVM** prensipleriyle geliştirilmiş modern bir iOS uygulaması.

---

## 🎯 Projenin Amacı ve Çözdüğü Sorunlar

Öğrenci evlerinde en sık yaşanan anlaşmazlıklar:
1. **"Sıra kimdeydi?" tartışmaları:** Bulaşık, çöp, tuvalet/banyo ve salon temizliği gibi işlerin kimin sırası olduğunun unutulması.
2. **Haber verilmeyen veya çakışan misafirler:** Aynı anda birden fazla kişinin misafir getirmesi veya sınav haftalarında habersiz yatılı misafir gelmesi.
3. **Takip edilemeyen ev masrafları ve ortak ihtiyaçlar:** Biten deterjan, peçete veya ortak market alışverişi borçlarının karışması.

**HighFive**, bu problemleri şeffaf, adil ve modüler bir mimariyle çözer. "İşini bitir, çak bir beşlik!" mantığıyla ev arkadaşları arasındaki huzuru korur.

---

## 🏗️ Mimari Yapı (Clean Architecture + MVVM + Repository Pattern)

Uygulama, hem gelecekte **Firebase / Supabase** gibi gerçek zamanlı bulut veritabanlarına kolayca bağlanabilmesi hem de **Android (Jetpack Compose + Kotlin)** platformuna 1:1 taşınabilmesi için katmanlı ve protokol odaklı tasarlanmıştır.

```
┌─────────────────────────────────────────────────────────────┐
│                       SwiftUI Views                         │
│   (DashboardView, ChoresView, GuestCalendarView, etc.)     │
└──────────────────────────────┬──────────────────────────────┘
                               │ binds to / observes
┌──────────────────────────────▼──────────────────────────────┐
│                        ViewModels                           │
│ (DashboardViewModel, ChoresViewModel, GuestViewModel, etc.) │
└──────────────────────────────┬──────────────────────────────┘
                               │ interacts with protocols
┌──────────────────────────────▼──────────────────────────────┐
│                    Repository Protocols                     │
│  (ChoreRepositoryProtocol, GuestRepositoryProtocol, etc.)   │
└──────────────┬──────────────────────────────┬───────────────┘
               │                              │
┌──────────────▼──────────────┐┌──────────────▼───────────────┐
│     InMemory / Mock Data    ││      Cloud Backend           │
│  (Şu an aktif - Geliştirme) ││  (Firebase / Supabase - Hazır)│
└─────────────────────────────┘└──────────────────────────────┘
```

### 📂 Proje Klasör Yapısı

```
HomeLife/
├── App/                            # Uygulama başlangıcı & Dependency Injection
│   ├── HomeLifeApp.swift
│   └── DependencyContainer.swift
│
├── Models/                         # Veri modelleri (Saf Swift struct'ları)
│   ├── Chore.swift                 # Ev işi modeli & döngü bilgisi
│   ├── ChoreLog.swift              # Tamamlanma geçmişi kaydı
│   ├── GuestVisit.swift            # Misafir ziyareti modeli
│   └── Roommate.swift              # Ev arkadaşı modeli
│
├── ViewModels/                     # Ekran mantığı ve durum yönetimi (MVVM)
│   ├── DashboardViewModel.swift
│   ├── ChoresViewModel.swift
│   ├── GuestCalendarViewModel.swift
│   └── HouseholdViewModel.swift
│
├── Views/                          # SwiftUI Görünümleri & Ekranlar
│   ├── Root/
│   │   └── MainTabView.swift       # 4 sekmeli alt menü
│   ├── Dashboard/
│   │   └── DashboardView.swift     # Günün özeti & hızlı aksiyonlar
│   ├── Chores/
│   │   ├── ChoresView.swift        # Sıralı & sabit ev işleri listesi
│   │   ├── ChoreRowView.swift      # Görev kartı bileşeni
│   │   ├── AddChoreSheet.swift     # Yeni görev ekleme
│   │   └── ChoreHistorySheet.swift # Görev tamamlama geçmişi
│   ├── Guests/
│   │   ├── GuestCalendarView.swift # Misafir takvimi & çakışma uyarısı
│   │   ├── GuestVisitRowView.swift # Ziyaret satır kartı
│   │   └── AddGuestSheet.swift     # Yeni misafir kaydı
│   └── Household/
│       ├── HouseholdView.swift     # Ev halkı yönetimi
│       └── AddRoommateSheet.swift  # Yeni ev arkadaşı ekleme
│
├── Repositories/                   # Veri katmanı (Protocols & InMemory)
│   ├── Protocols/
│   │   ├── ChoreRepositoryProtocol.swift
│   │   ├── GuestRepositoryProtocol.swift
│   │   └── RoommateRepositoryProtocol.swift
│   └── InMemory/
│       ├── InMemoryChoreRepository.swift
│       ├── InMemoryGuestRepository.swift
│       ├── InMemoryRoommateRepository.swift
│       └── MockDataFactory.swift
│
├── Common/                         # Ortak UI bileşenleri & Temalar
│   ├── Components/
│   │   ├── AvatarBadgeView.swift   # Dinamik avatar bileşeni
│   │   ├── StatusPillView.swift    # Durum rozeti
│   │   ├── GlassCardView.swift     # Kart kapsayıcı
│   │   └── EmptyStateView.swift    # Boş durum görünümü
│   ├── Theme/
│   │   └── AppTheme.swift          # Renk paleti & degradeler
│   └── Extensions/
│       └── Date+Extensions.swift   # Türkçe tarih formatlama
│
└── Resources/
    └── Assets.xcassets             # Renk ve ikon katalogları
```

---

## ✨ Mevcut Özellikler

### 1. 🔄 Ev İşleri ve Sıralama (Round-Robin Rotation)
- **Kimin Sırası?** Bulaşık, çöp, banyo ve salon temizliği gibi işlerde sıranın kimde olduğu avatar ve renklerle açıkça belirtilir.
- **Sıramı Tamamladım Butonu:** Görev tamamlandığında tek tuşla sıra otomatik olarak listedeki bir sonraki ev arkadaşına devreder (`currentAssigneeIndex = (currentAssigneeIndex + 1) % count`).
- **Gecikme & Acil Durum:** Bitiş tarihi geçen görevler kırmızı, bugün yapılması gerekenler sarı rozetle öne çıkarılır.
- **Sırayı Atla (Skip Turn):** Sınav haftası olan veya şehir dışında olan arkadaşın sırası, sebep belirtilerek bir sonrakine devredilebilir.
- **Görev Geçmişi (Log):** Hangi görevi kimin ne zaman tamamladığı tarih ve notlarla kayıt altına alınır.

### 2. 📅 Misafir Takvimi & Çakışma Önleme
- **Ziyaret Kaydı:** Kimin misafiri, kaç kişi, ne zaman gelip ne zaman gidecek ve nerede kalacak (salon çekyat, kendi odası vs.).
- **Yatılı / Günübirlik:** Konaklama tipi ve gece sayısı.
- **🚨 Akıllı Çakışma Kontrolü:** İki farklı ev arkadaşının misafir tarihleri çakıştığında otomatik kırmızı uyarı banner'ı gösterir.
- **Durum Güncelleme:** `Yaklaşan`, `Şu An Evde`, `Ayrıldı` ve `İptal`.

### 3. 👥 Ev Halkı Yönetimi
- Ev arkadaşlarının profilleri, odaları, telefon numaraları ve avatar renkleri.
- Kişi bazında aktif atanmış görev sayısı ve şu an sırası bekleyen görev sayısı istatistikleri.

---

## 🚀 Gelecek Yol Haritası (Sonraki Adımlar)

- [ ] **Ortak Masraf & Harcama Paylaşımı:** Mutfak alışverişleri ve faturaların Splitwise mantığıyla bölünmesi, borç dengesi hesabı.
- [ ] **Ortak İhtiyaç & Alışveriş Listesi:** Evde biten deterjan, yağ, çöp poşeti gibi malzemelerin ortak listeye eklenip işaretlenmesi.
- [ ] **Firebase / Supabase Gerçek Zamanlı Eşitleme:** Tek bir veritabanı ile tüm ev arkadaşlarının telefonlarının anlık senkronize olması.
- [ ] **Android Sürümü (Jetpack Compose):** Aynı veri protokolleri ve model yapısıyla Kotlin Android uygulamasının eklenmesi.
- [ ] **Bildirimler (Local & Push):** "Bugün çöp sırası sende!" hatırlatıcıları.

---

## 🛠️ Kurulum ve Çalıştırma

Projeyi bilgisayarınızda açmak ve çalıştırmak için:

```bash
# Projeyi Xcode ile açın
open HomeLife.xcodeproj
```

1. Xcode açıldığında üst bardan bir iOS Simülatörü seçin (örn. **iPhone 16 Pro** veya **iPhone 17**).
2. `Cmd + R` tuşlarına basarak projeyi derleyin ve simülatörde çalıştırın.

---

## 🌿 Git & Commit Standartları

Projeyi GitHub / GitLab / Bitbucket'a yüklerken **Conventional Commits** standardını kullanmanız önerilir:

- `feat:` Yeni bir özellik eklendiğinde (örn: `feat: add expense sharing module`)
- `fix:` Bir hata düzeltildiğinde (örn: `fix: resolve chore rotation index overflow`)
- `refactor:` Kod yapısı iyileştirildiğinde
- `docs:` Dokümantasyon güncellendiğinde
- `chore:` Yapılandırma veya bağımlılık güncellemelerinde
