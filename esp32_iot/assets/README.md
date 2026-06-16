# Hardware Documentation Assets

Letakkan file dokumentasi hardware Anda di folder ini.

## 📸 Recommended Files

### 1. Wiring Diagram
**Filename:** `wiring_diagram.png` atau `wiring_diagram.jpg`
- Diagram lengkap koneksi ESP32 → Radar → Relay
- Bisa dibuat dengan Fritzing, EasyEDA, atau draw.io
- Atau foto rangkaian breadboard yang jelas

### 2. Breadboard Layout (Optional)
**Filename:** `breadboard_layout.png`
- Layout breadboard untuk prototipe
- Helpful untuk reproduksi rangkaian

### 3. PCB Schematic (Optional)
**Filename:** `pcb_schematic.png`
- Jika membuat PCB custom
- Include both schematic dan PCB layout

### 4. Assembled Hardware Photo (Optional)
**Filename:** `assembled_hardware.jpg`
- Foto hardware yang sudah dirakit
- Multiple angles jika diperlukan

## 🎨 Tips Membuat Diagram

### Menggunakan Fritzing
1. Download [Fritzing](https://fritzing.org/)
2. Drag ESP32, HLK-LD2410C, Relay ke breadboard
3. Sambungkan sesuai pin configuration di README
4. Export: File → Export → as Image → PNG

### Menggunakan Draw.io
1. Buka [diagrams.net](https://app.diagrams.net/)
2. Gunakan shapes: Rectangle, Line, Text
3. Buat diagram block seperti di README
4. Export sebagai PNG

### Menggunakan Foto
1. Pastikan lighting yang cukup
2. Foto dari atas (bird's eye view)
3. Tandai setiap kabel dengan label jika perlu
4. Resolusi minimal 1920x1080px

## 📝 Cara Menggunakan

Setelah menambahkan gambar, edit `../README.md` dan uncomment baris:

```markdown
![Wiring Diagram](assets/wiring_diagram.png)
```

## 📐 Format File yang Disarankan

- **PNG** - Untuk diagram (lossless, background transparan)
- **JPG** - Untuk foto (lebih kecil file size)
- **SVG** - Untuk diagram vector (scalable, tapi GitHub preview terbatas)

**Max file size:** 5MB per file (GitHub recommendation)

