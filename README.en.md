<p align="center">
  <img src="assets/logo.png" alt="Tahweel Logo" width="200" />
</p>

<h1 align="center">Tahweel (تحويل)</h1>

<p align="center">
  <strong>Convert PDF files and images to text using Google Drive OCR</strong>
</p>

<p align="center">
  <a href="https://rubygems.org/gems/tahweel"><img src="https://img.shields.io/gem/v/tahweel.svg" alt="Gem Version" /></a>
  <a href="https://github.com/ieasybooks/tahweel.rb/blob/main/LICENSE.txt"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License" /></a>
  <img src="https://img.shields.io/badge/ruby-%3E%3D%203.2-ruby.svg" alt="Ruby Version" />
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#prerequisites">Prerequisites</a> •
  <a href="#authentication">Authentication</a> •
  <a href="#usage">Usage</a> •
  <a href="#api-reference">API Reference</a> •
  <a href="#contributing">Contributing</a>
</p>

<p align="center">
  <a href="README.md">🌐 العربية</a>
</p>

---

**Tahweel** (Arabic: تحويل, meaning "conversion") is a powerful Ruby gem for converting PDF files and images to editable text formats using Google Drive's OCR capabilities. It's especially optimized for Arabic text but works excellently with any language supported by Google's OCR engine.

## Features

- 🔤 **High-Quality OCR** — Leverages Google Drive's powerful OCR engine for accurate text extraction
- 📄 **Multiple Input Formats** — Supports PDF, JPG, JPEG, and PNG files
- 📝 **Multiple Output Formats** — Export to TXT, DOCX, or JSON
- 🌐 **Arabic Text Support** — Automatic right-to-left alignment detection for Arabic documents
- ⚡ **Concurrent Processing** — Multi-threaded processing at both file and page levels
- 📊 **Real-Time Progress** — Beautiful terminal UI with progress tracking per worker thread
- 🖥️ **Desktop GUI** — Cross-platform graphical interface with Arabic and English support
- 🔄 **Smart Skip Logic** — Automatically skips files when output already exists
- 📁 **Directory Structure Preservation** — Maintains input folder hierarchy in output
- 🛡️ **Robust Error Handling** — Exponential backoff retries for API rate limits

## Installation

### From RubyGems

```bash
gem install tahweel
```

### Using Bundler

Add this line to your application's Gemfile:

```ruby
gem 'tahweel'
```

Then run:

```bash
bundle install
```

### From Source

```bash
git clone https://github.com/ieasybooks/tahweel.rb.git
cd tahweel.rb
bundle install
```

## Prerequisites

### Ruby Version

Tahweel requires **Ruby 3.2.0** or higher.

### Poppler Utils

Tahweel uses Poppler utilities (`pdftoppm` and `pdfinfo`) for splitting PDF files into images.

**macOS:**
```bash
brew install poppler
```

**Ubuntu/Debian:**
```bash
sudo apt install poppler-utils
```

**Windows:**

Tahweel automatically downloads and installs Poppler binaries on Windows when first run.

### Google Account

You'll need a Google account to authenticate with Google Drive's OCR service. The first time you run Tahweel, it will open a browser window for OAuth authentication.

## Authentication

Tahweel uses OAuth 2.0 to authenticate with Google Drive. On first run:

1. A browser window will open automatically
2. Sign in with your Google account
3. Grant Tahweel permission to create and manage files in your Google Drive
4. After authorization, you'll see a success page and can close the browser

**Note:** Tahweel only creates temporary files for OCR processing and deletes them immediately after extraction. It uses the `drive.file` scope, which only allows access to files created by the application.

Your credentials are securely stored in:
- **Linux/macOS:** `~/.cache/tahweel/token.yaml`
- **Windows:** `%LOCALAPPDATA%\tahweel\token.yaml`

### Clearing Credentials

To remove stored credentials and re-authenticate:

```bash
tahweel-clear
```

## Usage

### Command-Line Interface

#### Basic Usage

Convert a single PDF file:

```bash
tahweel document.pdf
```

Convert all PDFs in a directory:

```bash
tahweel /path/to/documents/
```

#### Output Formats

Specify output formats (default: `txt,docx`):

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

#### Custom Output Directory

```bash
tahweel document.pdf -o /path/to/output/
```

#### Filter by File Extensions

```bash
# Process only PDF files
tahweel /path/to/documents/ -e pdf

# Process only images
tahweel /path/to/documents/ -e jpg,jpeg,png
```

#### Concurrency Settings

```bash
# Process 4 files concurrently
tahweel /path/to/documents/ -F 4

# Use 8 concurrent OCR operations per file
tahweel /path/to/documents/ -O 8
```

#### DPI Settings

Higher DPI produces better quality but slower processing:

```bash
tahweel document.pdf --dpi 300
```

#### Custom Page Separator (TXT output)

```bash
tahweel document.pdf --page-separator "\\n---PAGE BREAK---\\n"
```

### CLI Options Reference

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--extensions` | `-e` | File extensions to process | `pdf,jpg,jpeg,png` |
| `--dpi` | | DPI for PDF to image conversion | `150` |
| `--processor` | `-p` | OCR processor to use | `google_drive` |
| `--file-concurrency` | `-F` | Max concurrent files to process | `CPUs - 2` |
| `--ocr-concurrency` | `-O` | Max concurrent OCR operations | `12` |
| `--formats` | `-f` | Output formats (comma-separated) | `txt,docx` |
| `--page-separator` | | Page separator for TXT output | `\n\nPAGE_SEPARATOR\n\n` |
| `--output` | `-o` | Output directory | Input file directory |
| `--version` | `-v` | Display version | |

### Graphical User Interface

Launch the desktop GUI:

```bash
tahweel-ui
```

The GUI provides:
- Single file or folder conversion
- Arabic and English interface
- Progress tracking for both global and per-file progress
- Automatic opening of output directory on completion

### Progress Display

The CLI shows a real-time progress dashboard:

```
Total Progress: [3/10] 30.0% | Time: 45s
 [Worker 1] document1.pdf | Ocr        | 75.0% (6/8)
 [Worker 2] document2.pdf | Splitting  | 50.0% (5/10)
 [Worker 3] Idle
 [Worker 4] document4.pdf | Ocr        | 25.0% (2/8)
```

## Output Formats

### TXT (Plain Text)

Simple text output with configurable page separators:

```
Page 1 content here...

PAGE_SEPARATOR

Page 2 content here...
```

### DOCX (Microsoft Word)

Formatted Word documents with:
- One page of content per document page
- Automatic text direction (RTL for Arabic, LTR otherwise)
- Normalized line endings compatible with all platforms
- Intelligent line merging for better readability

### JSON (Structured Data)

Page-by-page structured output:

```json
[
  {
    "page": 1,
    "content": "Page 1 content here..."
  },
  {
    "page": 2,
    "content": "Page 2 content here..."
  }
]
```

## API Reference

### Converting PDF Files

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

### Extracting Text from Images

```ruby
require 'tahweel'

# Extract text from a single image
text = Tahweel.extract('image.png')
text = Tahweel.extract('photo.jpg', processor: :google_drive)
```

### Writing Output Files

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

### Full Processing Pipeline

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

### Collecting Files from Directory

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

## Examples

### Batch Convert Arabic Books

```bash
# Convert all PDFs in an Arabic books directory with high quality
tahweel ~/arabic-books/ -f txt,docx --dpi 200 -o ~/converted-books/
```

### Process Scanned Documents

```bash
# Convert scanned images to searchable text
tahweel ~/scanned-docs/ -e jpg,png -f txt -o ~/ocr-output/
```

### Library Integration

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

## Troubleshooting

### File Descriptor Limits

If you encounter connection errors or freezing with large batches:

```bash
ulimit -n 4096
```

### Rate Limiting

Tahweel automatically handles Google API rate limits with exponential backoff. If you still encounter issues, try reducing concurrency:

```bash
tahweel documents/ -F 2 -O 6
```

### Poppler Not Found

Ensure Poppler is installed and in your PATH:

```bash
which pdftoppm  # Should return a path
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ieasybooks/tahweel.rb.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development

After checking out the repo:

```bash
bin/setup          # Install dependencies
rake spec          # Run tests
bin/console        # Interactive prompt
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Tahweel project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/ieasybooks/tahweel.rb/blob/main/CODE_OF_CONDUCT.md).

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/ieasybooks">iEasyBooks</a>
</p>
