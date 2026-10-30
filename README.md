> **مؤرشف:** لم يعد هذا المستودع قيد الصيانة. الإصدار الجديد الذي تتم صيانته هو [tahweel-rs](https://github.com/ieasybooks/tahweel-rs).
>
> التوثيق أدناه يخص هذا الإصدار المؤرشف.

<p align="center">
  <img src="assets/logo.png" alt="شعار تحويل" width="200" />
</p>

<h1 dir="rtl" align="center">تحويل (Tahweel)</h1>

<p dir="rtl" align="center">
  <strong>تحويل ملفات PDF والصور إلى نصوص باستخدام التعرف الضوئي من Google Drive</strong>
</p>

<p align="center">
  <a href="https://rubygems.org/gems/tahweel"><img src="https://img.shields.io/gem/v/tahweel.svg" alt="إصدار الجوهرة" /></a>
  <a href="https://github.com/ieasybooks/tahweel.rb/blob/main/LICENSE.txt"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="الرخصة" /></a>
  <img src="https://img.shields.io/badge/ruby-%3E%3D%203.2-ruby.svg" alt="إصدار Ruby" />
</p>

<p align="center">
  <a href="#المميزات">المميزات</a> •
  <a href="#التثبيت">التثبيت</a> •
  <a href="#المتطلبات">المتطلبات</a> •
  <a href="#المصادقة">المصادقة</a> •
  <a href="#الاستخدام">الاستخدام</a> •
  <a href="#واجهة-البرمجة">واجهة البرمجة</a> •
  <a href="#المساهمة">المساهمة</a>
</p>

<p align="center">
  <a href="README.en.md">🌐 English</a>
</p>

---

<p dir="rtl"><strong>تحويل</strong> (بالإنجليزية: Tahweel، وتعني "التحويل") هي أداة Ruby قوية لتحويل ملفات PDF والصور إلى نصوص قابلة للتحرير باستخدام تقنية التعرف الضوئي من Google Drive. تم تحسينها بشكل خاص للنصوص العربية، لكنها تعمل بامتياز مع جميع اللغات التي يدعمها محرك Google.</p>

<h2 dir="rtl">المميزات</h2>

<ul dir="rtl">
  <li>🔤 <strong>تعرف ضوئي عالي الجودة</strong> — يستخدم محرك Google Drive القوي لاستخراج النصوص بدقة</li>
  <li>📄 <strong>صيغ إدخال متعددة</strong> — يدعم ملفات PDF و JPG و JPEG و PNG</li>
  <li>📝 <strong>صيغ إخراج متعددة</strong> — تصدير إلى TXT أو DOCX أو JSON</li>
  <li>🌐 <strong>دعم النصوص العربية</strong> — اكتشاف تلقائي لاتجاه النص من اليمين لليسار</li>
  <li>⚡ <strong>معالجة متزامنة</strong> — معالجة متعددة الخيوط على مستوى الملفات والصفحات</li>
  <li>📊 <strong>تتبع التقدم اللحظي</strong> — واجهة طرفية جميلة مع تتبع التقدم لكل خيط</li>
  <li>🖥️ <strong>واجهة رسومية</strong> — واجهة سطح مكتب عبر المنصات بالعربية والإنجليزية</li>
  <li>🔄 <strong>تخطي ذكي</strong> — يتخطى الملفات تلقائياً عندما يكون الإخراج موجوداً</li>
  <li>📁 <strong>الحفاظ على هيكل المجلدات</strong> — يحافظ على التسلسل الهرمي للمجلدات في الإخراج</li>
  <li>🛡️ <strong>معالجة أخطاء قوية</strong> — إعادة المحاولة بتأخير تصاعدي لحدود واجهة البرمجة</li>
</ul>

<h2 dir="rtl">التثبيت</h2>

<h3 dir="rtl">من RubyGems</h3>

```bash
gem install tahweel
```

<h3 dir="rtl">باستخدام Bundler</h3>

<p dir="rtl">أضف هذا السطر إلى ملف Gemfile الخاص بتطبيقك:</p>

```ruby
gem 'tahweel'
```

<p dir="rtl">ثم نفّذ:</p>

```bash
bundle install
```

<h3 dir="rtl">من المصدر</h3>

```bash
git clone https://github.com/ieasybooks/tahweel.rb.git
cd tahweel.rb
bundle install
```

<h2 dir="rtl">المتطلبات</h2>

<h3 dir="rtl">إصدار Ruby</h3>

<p dir="rtl">يتطلب تحويل <strong>Ruby 3.2.0</strong> أو أحدث.</p>

<h3 dir="rtl">أدوات Poppler</h3>

<p dir="rtl">يستخدم تحويل أدوات Poppler (<code dir="ltr">pdftoppm</code> و <code dir="ltr">pdfinfo</code>) لتقسيم ملفات PDF إلى صور.</p>

<p dir="rtl"><strong>macOS:</strong></p>

```bash
brew install poppler
```

<p dir="rtl"><strong>Ubuntu/Debian:</strong></p>

```bash
sudo apt install poppler-utils
```

<p dir="rtl"><strong>Windows:</strong></p>

<p dir="rtl">يقوم تحويل بتنزيل وتثبيت Poppler تلقائياً على Windows عند التشغيل لأول مرة.</p>

<h3 dir="rtl">حساب Google</h3>

<p dir="rtl">ستحتاج إلى حساب Google للمصادقة مع خدمة التعرف الضوئي في Google Drive. في أول تشغيل لتحويل، سيفتح نافذة متصفح للمصادقة عبر OAuth.</p>

<h2 dir="rtl">المصادقة</h2>

<p dir="rtl">يستخدم تحويل OAuth 2.0 للمصادقة مع Google Drive. عند التشغيل لأول مرة:</p>

<ol dir="rtl">
  <li>ستفتح نافذة متصفح تلقائياً</li>
  <li>سجّل الدخول بحسابك في Google</li>
  <li>امنح تحويل صلاحية إنشاء وإدارة الملفات في Google Drive الخاص بك</li>
  <li>بعد المصادقة، سترى صفحة نجاح ويمكنك إغلاق المتصفح</li>
</ol>

<p dir="rtl"><strong>ملاحظة:</strong> يقوم تحويل فقط بإنشاء ملفات مؤقتة لمعالجة التعرف الضوئي ويحذفها فوراً بعد الاستخراج. يستخدم نطاق <code dir="ltr">drive.file</code> الذي يسمح فقط بالوصول إلى الملفات التي أنشأها التطبيق.</p>

<p dir="rtl">يتم تخزين بيانات الاعتماد بشكل آمن في:</p>

<ul dir="rtl">
  <li><strong>Linux/macOS:</strong> <code dir="ltr">~/.cache/tahweel/token.yaml</code></li>
  <li><strong>Windows:</strong> <code dir="ltr">%LOCALAPPDATA%\tahweel\token.yaml</code></li>
</ul>

<h3 dir="rtl">مسح بيانات الاعتماد</h3>

<p dir="rtl">لإزالة بيانات الاعتماد المخزنة وإعادة المصادقة:</p>

```bash
tahweel-clear
```

<h2 dir="rtl">الاستخدام</h2>

<h3 dir="rtl">واجهة سطر الأوامر</h3>

<h4 dir="rtl">الاستخدام الأساسي</h4>

<p dir="rtl">تحويل ملف PDF واحد:</p>

```bash
tahweel document.pdf
```

<p dir="rtl">تحويل جميع ملفات PDF في مجلد:</p>

```bash
tahweel /path/to/documents/
```

<h4 dir="rtl">صيغ الإخراج</h4>

<p dir="rtl">تحديد صيغ الإخراج (الافتراضي: <code dir="ltr">txt,docx</code>):</p>

```bash
# Text only
tahweel document.pdf -f txt

# DOCX only
tahweel document.pdf -f docx

# JSON only
tahweel document.pdf -f json

# Multiple formats
tahweel document.pdf -f txt,docx,json
```

<h4 dir="rtl">مجلد إخراج مخصص</h4>

```bash
tahweel document.pdf -o /path/to/output/
```

<h4 dir="rtl">التصفية حسب امتدادات الملفات</h4>

```bash
# Process only PDF files
tahweel /path/to/documents/ -e pdf

# Process only images
tahweel /path/to/documents/ -e jpg,jpeg,png
```

<h4 dir="rtl">إعدادات التزامن</h4>

```bash
# Process 4 files concurrently
tahweel /path/to/documents/ -F 4

# Use 8 concurrent OCR operations per file
tahweel /path/to/documents/ -O 8
```

<h4 dir="rtl">إعدادات DPI</h4>

<p dir="rtl">DPI أعلى ينتج جودة أفضل لكن معالجة أبطأ:</p>

```bash
tahweel document.pdf --dpi 300
```

<h4 dir="rtl">فاصل صفحات مخصص (إخراج TXT)</h4>

```bash
tahweel document.pdf --page-separator "\\n---PAGE BREAK---\\n"
```

<h3 dir="rtl">مرجع خيارات سطر الأوامر</h3>

<div dir="rtl">

| الخيار | المختصر | الوصف | الافتراضي |
|--------|---------|-------|-----------|
| `--extensions` | `-e` | امتدادات الملفات للمعالجة | `pdf,jpg,jpeg,png` |
| `--dpi` | | DPI لتحويل PDF إلى صورة | `150` |
| `--processor` | `-p` | معالج OCR المستخدم | `google_drive` |
| `--file-concurrency` | `-F` | أقصى عدد ملفات للمعالجة المتزامنة | `المعالجات - 2` |
| `--ocr-concurrency` | `-O` | أقصى عمليات OCR متزامنة | `12` |
| `--formats` | `-f` | صيغ الإخراج (مفصولة بفواصل) | `txt,docx` |
| `--page-separator` | | فاصل الصفحات لإخراج TXT | `\n\nPAGE_SEPARATOR\n\n` |
| `--output` | `-o` | مجلد الإخراج | مجلد ملف الإدخال |
| `--version` | `-v` | عرض الإصدار | |

</div>

<h3 dir="rtl">الواجهة الرسومية</h3>

<p dir="rtl">لتشغيل واجهة سطح المكتب:</p>

```bash
tahweel-ui
```

<p dir="rtl">توفر الواجهة الرسومية:</p>

<ul dir="rtl">
  <li>تحويل ملف واحد أو مجلد كامل</li>
  <li>واجهة بالعربية والإنجليزية</li>
  <li>تتبع التقدم للمستوى العام ولكل ملف</li>
  <li>فتح مجلد الإخراج تلقائياً عند الانتهاء</li>
</ul>

<h3 dir="rtl">عرض التقدم</h3>

<p dir="rtl">تعرض واجهة سطر الأوامر لوحة تقدم لحظية:</p>

```
Total Progress: [3/10] 30.0% | Time: 45s
 [Worker 1] document1.pdf | Ocr        | 75.0% (6/8)
 [Worker 2] document2.pdf | Splitting  | 50.0% (5/10)
 [Worker 3] Idle
 [Worker 4] document4.pdf | Ocr        | 25.0% (2/8)
```

<h2 dir="rtl">صيغ الإخراج</h2>

<h3 dir="rtl">TXT (نص عادي)</h3>

<p dir="rtl">إخراج نصي بسيط مع فواصل صفحات قابلة للتخصيص:</p>

```
محتوى الصفحة 1 هنا...

PAGE_SEPARATOR

محتوى الصفحة 2 هنا...
```

<h3 dir="rtl">DOCX (Microsoft Word)</h3>

<p dir="rtl">مستندات Word منسقة مع:</p>

<ul dir="rtl">
  <li>صفحة محتوى واحدة لكل صفحة مستند</li>
  <li>اتجاه نص تلقائي (RTL للعربية، LTR لغيرها)</li>
  <li>فواصل أسطر متوافقة مع جميع المنصات</li>
  <li>دمج ذكي للأسطر لقراءة أفضل</li>
</ul>

<h3 dir="rtl">JSON (بيانات منظمة)</h3>

<p dir="rtl">إخراج منظم صفحة بصفحة:</p>

```json
[
  {
    "page": 1,
    "content": "محتوى الصفحة 1 هنا..."
  },
  {
    "page": 2,
    "content": "محتوى الصفحة 2 هنا..."
  }
]
```

<h2 dir="rtl">واجهة البرمجة</h2>

<h3 dir="rtl">تحويل ملفات PDF</h3>

```ruby
require 'tahweel'

# Convert a PDF to text (returns array of page texts)
pages = Tahweel.convert('document.pdf')

# With options
pages = Tahweel.convert(
  'document.pdf',
  dpi: 300,              # Higher quality
  processor: :google_drive,
  concurrency: 8
)

# With progress tracking
pages = Tahweel.convert('document.pdf') do |progress|
  puts "Stage: #{progress[:stage]}"
  puts "Progress: #{progress[:percentage]}%"
  puts "Current page: #{progress[:current_page]}"
end
```

<h3 dir="rtl">استخراج النص من الصور</h3>

```ruby
require 'tahweel'

# Extract text from a single image
text = Tahweel.extract('image.png')
text = Tahweel.extract('photo.jpg', processor: :google_drive)
```

<h3 dir="rtl">كتابة ملفات الإخراج</h3>

```ruby
require 'tahweel'

pages = Tahweel.convert('document.pdf')

# Write to multiple formats
Tahweel::Writer.write(pages, 'output', formats: [:txt, :docx, :json])

# Write to a single format with options
Tahweel::Writer.write(
  pages,
  'output',
  formats: [:txt],
  page_separator: "\n---\n"
)
```

<h3 dir="rtl">خط معالجة كامل</h3>

```ruby
require 'tahweel'

# Using the CLI FileProcessor for complete workflow
Tahweel::CLI::FileProcessor.process('document.pdf', {
  dpi: 150,
  processor: :google_drive,
  ocr_concurrency: 12,
  formats: [:txt, :docx],
  output: '/path/to/output'
}) do |progress|
  puts "#{progress[:stage]}: #{progress[:percentage]}%"
end
```

<h3 dir="rtl">جمع الملفات من مجلد</h3>

```ruby
require 'tahweel'

# Get all supported files in a directory
files = Tahweel::CLI::FileCollector.collect('/path/to/documents/')

# Filter by specific extensions
files = Tahweel::CLI::FileCollector.collect(
  '/path/to/documents/',
  extensions: ['pdf']
)
```

<h2 dir="rtl">أمثلة</h2>

<h3 dir="rtl">تحويل دفعي للكتب العربية</h3>

```bash
# Convert all PDFs in an Arabic books directory with high quality
tahweel ~/arabic-books/ -f txt,docx --dpi 200 -o ~/converted-books/
```

<h3 dir="rtl">معالجة المستندات الممسوحة ضوئياً</h3>

```bash
# Convert scanned images to searchable text
tahweel ~/scanned-docs/ -e jpg,png -f txt -o ~/ocr-output/
```

<h3 dir="rtl">التكامل مع المكتبة</h3>

```ruby
require 'tahweel'

# Convert and process in your application
def process_document(pdf_path)
  pages = Tahweel.convert(pdf_path) do |progress|
    update_progress_bar(progress[:percentage])
  end

  # Process the extracted text
  full_text = pages.join("\n\n")
  word_count = full_text.split.size

  {
    pages: pages.size,
    words: word_count,
    text: full_text
  }
end
```

<h2 dir="rtl">استكشاف الأخطاء وإصلاحها</h2>

<h3 dir="rtl">حدود واصفات الملفات</h3>

<p dir="rtl">إذا واجهت أخطاء اتصال أو تجمد مع دفعات كبيرة:</p>

```bash
ulimit -n 4096
```

<h3 dir="rtl">تحديد المعدل</h3>

<p dir="rtl">يتعامل تحويل تلقائياً مع حدود معدل Google API بتأخير تصاعدي. إذا استمرت المشاكل، جرّب تقليل التزامن:</p>

```bash
tahweel documents/ -F 2 -O 6
```

<h3 dir="rtl">Poppler غير موجود</h3>

<p dir="rtl">تأكد من تثبيت Poppler وأنه في مسار PATH:</p>

```bash
which pdftoppm  # Should return a path
```

<h2 dir="rtl">المساهمة</h2>

<p dir="rtl">تقارير الأخطاء وطلبات السحب مرحب بها على GitHub في https://github.com/ieasybooks/tahweel.rb.</p>

<ol dir="rtl">
  <li>انسخ المستودع (Fork)</li>
  <li>أنشئ فرع الميزة (<code dir="ltr">git checkout -b feature/amazing-feature</code>)</li>
  <li>ثبّت تغييراتك (<code dir="ltr">git commit -am 'Add amazing feature'</code>)</li>
  <li>ادفع إلى الفرع (<code dir="ltr">git push origin feature/amazing-feature</code>)</li>
  <li>افتح طلب سحب (Pull Request)</li>
</ol>

<h3 dir="rtl">التطوير</h3>

<p dir="rtl">بعد استنساخ المستودع:</p>

```bash
bin/setup          # Install dependencies
rake spec          # Run tests
bin/console        # Interactive prompt
```

<h2 dir="rtl">الرخصة</h2>

<p dir="rtl">هذه الأداة متاحة كمصدر مفتوح بموجب شروط <a href="https://opensource.org/licenses/MIT">رخصة MIT</a>.</p>

<h2 dir="rtl">قواعد السلوك</h2>

<p dir="rtl">يُتوقع من جميع المتفاعلين في مشروع تحويل اتباع <a href="https://github.com/ieasybooks/tahweel.rb/blob/main/CODE_OF_CONDUCT.md">قواعد السلوك</a>.</p>

---

<p dir="rtl" align="center">صُنع بـ ❤️ بواسطة <a href="https://github.com/ieasybooks">iEasyBooks</a></p>
