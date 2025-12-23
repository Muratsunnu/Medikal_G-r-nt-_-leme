function MedikalArayuz
    % ---------------------------------------------------------------------
    % Amaç: Gürültülü kemik sintigrafisi görüntülerini adım adım iyileştirmek.
    % ---------------------------------------------------------------------

    % PENCERE AYARLARI
    % İskelet görüntüleri ve grafiklerin sığması için geniş ve yüksek bir pencere oluşturulur.
    fig = uifigure('Name', 'MedEnhance - Bone Scan Edition', ...
        'Position', [50 30 1200 800], 'Color', [0.96 0.96 0.96]); 
    
    % BAŞLIK
    uilabel(fig, 'Text', 'Medikal Görüntü Onarım Projesi (İskelet/Bone Scan)', ...
        'Position', [20 760 800 30], 'FontSize', 22, 'FontWeight', 'bold', 'FontColor', [0.2 0.2 0.2]);

    % VERİ SAKLAMA YAPISI (DATA STRUCT)
    % Her işlem adımındaki görüntüyü hafızada tutmak için kullanılır.
    appData = struct('Orijinal', [], 'Gurultulu', [], 'Median', [], 'Histeq', [], 'Final', []);

    % ---------------------------------------------------------
    % EKSEN (AXES) AYARLARI
    % İskelet görüntüleri dikey (portrait) formatta olduğu için 
    % eksen boyutları 180x300 olarak ayarlanmıştır.
    % ---------------------------------------------------------
    
    % 1. Orijinal Görüntü Alanı
    ax1 = uiaxes(fig, 'Position', [30 430 180 300], 'BackgroundColor', [0.1 0.1 0.1]);
    title(ax1, '1. Orijinal', 'Color', 'white'); ax1.XTick=[]; ax1.YTick=[];
    
    % 2. Gürültülü (Simülasyon) Görüntü Alanı
    ax2 = uiaxes(fig, 'Position', [230 430 180 300], 'BackgroundColor', [0.1 0.1 0.1]);
    title(ax2, '2. Gürültülü', 'Color', 'white'); ax2.XTick=[]; ax2.YTick=[];

    % 3. Median Filtre Sonucu Alanı
    ax3 = uiaxes(fig, 'Position', [430 430 180 300], 'BackgroundColor', [0.1 0.1 0.1]);
    title(ax3, '3. Median (Temiz)', 'Color', 'white'); ax3.XTick=[]; ax3.YTick=[];

    % 4. Histogram Eşitleme Sonucu Alanı
    ax4 = uiaxes(fig, 'Position', [630 430 180 300], 'BackgroundColor', [0.1 0.1 0.1]);
    title(ax4, '4. Adaptive Histeq', 'Color', 'white'); ax4.XTick=[]; ax4.YTick=[];

    % 5. Final (Keskinleştirme) Sonucu Alanı
    ax5 = uiaxes(fig, 'Position', [830 430 180 300], 'BackgroundColor', [0.1 0.1 0.1]);
    title(ax5, '5. Final (Keskin)', 'Color', 'white'); ax5.XTick=[]; ax5.YTick=[];
    
    % ---------------------------------------------------------
    % HİSTOGRAM GRAFİKLERİ (ANALİZ)
    % Görüntünün gri seviye dağılımını işlem öncesi ve sonrası karşılaştırmak için.
    % ---------------------------------------------------------
    axHistOncesi = uiaxes(fig, 'Position', [150 200 400 120]);
    title(axHistOncesi, 'Grafik A: İşlem Öncesi Dağılım'); grid(axHistOncesi, 'on');
    
    axHistSonrasi = uiaxes(fig, 'Position', [650 200 400 120]);
    title(axHistSonrasi, 'Grafik B: İşlem Sonrası Dağılım'); grid(axHistSonrasi, 'on');

    % DURUM BİLGİSİ ETİKETİ
    lblBilgi = uilabel(fig, 'Text', 'Başlamak için mavi butona tıklayınız.', ...
        'Position', [50 150 800 30], 'FontSize', 16, 'FontWeight', 'bold', 'FontColor', [0.2 0.2 0.2]);

    % ---------------------------------------------------------
    % KONTROL BUTONLARI
    % Kullanıcıyı işlem sırasına göre yönlendiren renkli butonlar.
    % ---------------------------------------------------------
    
    % Adım 1: Yükle ve Boz
    btn1 = uibutton(fig, 'push', 'Text', '1. Yükle ve Boz', ...
        'Position', [80 80 160 50], 'BackgroundColor', [0.0 0.45 0.74], 'FontColor', 'white', ...
        'FontSize', 14, 'FontWeight', 'bold', 'ButtonPushedFcn', @(btn,event) Adim1_YukleBoz());

    % Adım 2: Median Filtre
    btn2 = uibutton(fig, 'push', 'Text', '2. Median Uygula', ...
        'Position', [260 80 160 50], 'BackgroundColor', [0.85 0.33 0.1], 'FontColor', 'white', ...
        'FontSize', 14, 'FontWeight', 'bold', 'Enable', 'off', 'ButtonPushedFcn', @(btn,event) Adim2_Median());

    % Adım 3: Histogram İşleme
    btn3 = uibutton(fig, 'push', 'Text', '3. Histeq Yap', ...
        'Position', [440 80 160 50], 'BackgroundColor', [0.49 0.18 0.56], 'FontColor', 'white', ...
        'FontSize', 14, 'FontWeight', 'bold', 'Enable', 'off', 'ButtonPushedFcn', @(btn,event) Adim3_Histeq());

    % Adım 4: Keskinleştirme
    btn4 = uibutton(fig, 'push', 'Text', '4. KESKİNLEŞTİR', ...
        'Position', [620 80 180 50], 'BackgroundColor', [0.1 0.6 0.3], 'FontColor', 'white', ...
        'FontSize', 15, 'FontWeight', 'bold', 'Enable', 'off', 'ButtonPushedFcn', @(btn,event) Adim4_Sharpen());

    % Ekstra: Detaylı İnceleme (Zoom)
    btnZoom = uibutton(fig, 'push', 'Text', '🔍 SONUCU İNCELE', ...
        'Position', [850 80 200 50], 'BackgroundColor', [0.2 0.2 0.2], 'FontColor', 'white', ...
        'FontSize', 14, 'FontWeight', 'bold', 'Enable', 'off', ...
        'ButtonPushedFcn', @(btn,event) SonucuAc());

    % ---------------------------------------------------------
    % FONKSİYONLAR (ALGORİTMA ADIMLARI)
    % ---------------------------------------------------------
    
    function Adim1_YukleBoz()
        % Kullanıcıdan dosya seçmesini ister
        [file, path] = uigetfile({'*.jpg;*.png;*.jpeg;*.tif', 'Görsel Dosyaları'});
        if isequal(file,0), return; end
        % ASIL ÖNEMLİ NOKTA
        % Görüntüyü okur ve RGB ise Gri Seviyeye dönüştürür
        raw = imread(fullfile(path, file));
        if size(raw,3)==3, raw=rgb2gray(raw); end
        appData.Orijinal = raw;
        
        % Bozuk sensör simülasyonu için 'Salt & Pepper' gürültüsü ekler
        appData.Gurultulu = imnoise(raw, 'salt & pepper', 0.05);
        
        % İlk iki aşamayı göster
        imshow(appData.Orijinal, 'Parent', ax1);
        imshow(appData.Gurultulu, 'Parent', ax2);
        
        % Yeni resim yüklendiğinde eski sonuçları temizle
        cla(ax3); cla(ax4); cla(ax5); cla(axHistOncesi); cla(axHistSonrasi);
        
        lblBilgi.Text = 'Görüntü yüklendi ve gürültü eklendi. Temizlemek için turuncu butona basın ->';
        lblBilgi.FontColor = [0.0 0.45 0.74];
        btn2.Enable = 'on'; % Bir sonraki butonu aktif et
    end

    function Adim2_Median()
        % 'Salt & Pepper' gürültüsünü en iyi temizleyen Median Filtresi (3x3) uygulanır.
        % Ortalama (Average) filtresi tercih edilmemiştir çünkü görüntüyü bulanıklaştırır.
        appData.Median = medfilt2(appData.Gurultulu, [3 3]);
        
        imshow(appData.Median, 'Parent', ax3);
        
        lblBilgi.Text = 'Gürültü temizlendi. Kontrastı iyileştirmek için mor butona basın ->';
        lblBilgi.FontColor = [0.85 0.33 0.1];
        btn3.Enable = 'on';
    end

    function Adim3_Histeq()
        % Arka planı siyah olan iskelet görüntüleri için standart histeq yerine
        % 'Contrast Limited Adaptive Histogram Equalization' (CLAHE) kullanılır.
        % Bu yöntem siyah arka planın grileşmesini engeller.
        appData.Histeq = adapthisteq(appData.Median, 'ClipLimit', 0.02, 'Distribution', 'rayleigh');
        
        imshow(appData.Histeq, 'Parent', ax4);
        
        % Histogramları çiz (Öncesi ve Sonrası karşılaştırması)
        histogram(axHistOncesi, appData.Median, 'BinWidth', 5, 'FaceColor', [0.6 0.6 0.6], 'EdgeColor', 'none');
        axHistOncesi.XLim = [0 255];
        
        histogram(axHistSonrasi, appData.Histeq, 'BinWidth', 5, 'FaceColor', [0.0 0.45 0.74], 'EdgeColor', 'none');
        axHistSonrasi.XLim = [0 255];
        
        lblBilgi.Text = 'Kontrast dengelendi. Son dokunuş (detay vurgusu) için yeşil butona basın ->';
        lblBilgi.FontColor = [0.49 0.18 0.56];
        btn4.Enable = 'on';
    end

    function Adim4_Sharpen()
        % 'Unsharp Masking' yöntemi ile kemik kenarları keskinleştirilir.
        appData.Final = imsharpen(appData.Histeq, 'Radius', 1, 'Amount', 1.5);
        
        imshow(appData.Final, 'Parent', ax5);
        
        % Başarım Metriği: PSNR (Peak Signal-to-Noise Ratio) hesaplanması
        err = immse(appData.Final, appData.Orijinal);
        psnr_val = 10 * log10(255^2 / err);
        
        lblBilgi.Text = sprintf('İŞLEM BİTTİ! Kalite (PSNR): %.2f dB. Detay için SİYAH butona basın.', psnr_val);
        lblBilgi.FontColor = [0.1 0.6 0.3];
        btnZoom.Enable = 'on'; 
    end

    function SonucuAc()
        % Sonuç görüntüsünü detaylı incelemek için yeni, tam ekran bir pencere açar.
        figure('Name', 'Detaylı İnceleme', 'NumberTitle', 'off', 'Color', 'black');
        imshow(appData.Final, 'Border', 'tight');
        title('Final Görüntü (Tam Ekran İnceleme)', 'Color', 'white', 'FontSize', 16);
        zoom on; % Yakınlaştırma (Zoom) özelliğini aktif eder
    end
end
