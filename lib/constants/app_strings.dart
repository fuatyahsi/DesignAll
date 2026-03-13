class AppStrings {
  AppStrings._();

  // App
  static const appName = 'DesignAll';
  static const appTagline = 'Proje & Tasarım Asistanı';

  // Auth
  static const login = 'Giriş Yap';
  static const register = 'Kayıt Ol';
  static const email = 'E-posta';
  static const password = 'Şifre';
  static const fullName = 'Ad Soyad';
  static const forgotPassword = 'Şifremi Unuttum';
  static const resetPassword = 'Şifre Sıfırla';
  static const noAccount = 'Hesabın yok mu?';
  static const hasAccount = 'Zaten hesabın var mı?';
  static const loginSuccess = 'Giriş başarılı!';
  static const registerSuccess = 'Kayıt başarılı! E-postanı kontrol et.';

  // Dashboard
  static const myProjects = 'Projelerim';
  static const newProject = 'Yeni Proje';
  static const noProjects = 'Henüz hiç proje eklenmemiş.';
  static const activeProjects = 'Aktif Projeler';
  static const completedProjects = 'Tamamlanan';

  // Project
  static const projectName = 'Proje Adı';
  static const projectLocation = 'Konum / Bilgi';
  static const takePhoto = 'Fotoğraf Çek';
  static const saveProject = 'PROJEYİ KAYDET';
  static const projectSaved = 'Proje başarıyla kaydedildi!';
  static const fillRequired = 'Lütfen bir isim yazın ve fotoğraf çekin!';
  static const colorPalette = 'Renk Paleti';
  static const projectNotes = 'Proje Notları';

  // AR
  static const arMeasurement = 'AR Ölçü Aracı';
  static const arInstruction = 'Ölçüm için iki noktaya dokunun';
  static const distanceLabel = 'Mesafe';

  // Room / Space Types
  static const roomTypes = [
    'Salon', 'Yatak Odası', 'Mutfak', 'Banyo',
    'Çocuk Odası', 'Ofis', 'Balkon', 'Giriş',
    'Yemek Odası', 'Koridor', 'Bahçe', 'Garaj', 'Diğer',
  ];

  // Project Status
  static const statusActive = 'active';
  static const statusCompleted = 'completed';
  static const statusPaused = 'paused';

  // Budget Categories
  static const budgetCategories = [
    'Mobilya', 'Boya & Duvar', 'Aydınlatma', 'Zemin',
    'Tekstil', 'Aksesuar', 'İşçilik', 'Nakliye',
    'Elektronik', 'Dekorasyon', 'Diğer',
  ];

  // Onboarding
  static const onboardingTitle1 = 'Projelerini Yönet';
  static const onboardingDesc1 = 'Tüm projelerini tek bir yerden kolayca takip et.';
  static const onboardingTitle2 = 'AR ile Ölç';
  static const onboardingDesc2 = 'Artırılmış gerçeklik ile mekanları santimetrik hassasiyetle ölç.';
  static const onboardingTitle3 = 'Renk Paleti Çıkar';
  static const onboardingDesc3 = 'Fotoğraflardan otomatik renk paleti oluştur ve projelerine ilham kat.';
  static const onboardingTitle4 = 'Haydi Başlayalım';
  static const onboardingDesc4 = 'Kişisel proje asistanın hazır. Hemen ilk projeni oluştur!';
  static const getStarted = 'Başla';
  static const skip = 'Atla';
  static const next = 'İleri';
}
