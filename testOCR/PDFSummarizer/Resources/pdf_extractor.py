# pdf_extractor.py

from docling.document_converter import DocumentConverter
from pypdf import PdfReader

def extract_text(path, method="docling"):
    print(f">>> extract_text() called with method: {method}")
    print(f">>> Target PDF path: {path}")

    if method == "docling":
        try:
            print("Initializing DocumentConverter...")
            converter = DocumentConverter()

            print("Converting PDF using docling...")
            result = converter.convert(path)

            print("Conversion complete, exporting to markdown...")
            markdown = result.document.export_to_markdown()

            print("Finished docling export.")
            return markdown
        except Exception as e:
            print(f"docling error: {e}")
            return f"[docling error] {e}"

    elif method == "pypdf":
        try:
            print("Loading PDF using pypdf...")
            reader = PdfReader(path)

            print(f"Number of pages: {len(reader.pages)}")
            all_text = []

            for i, page in enumerate(reader.pages):
                print(f"Extracting text from page {i+1}...")
                text = page.extract_text() or ""
                all_text.append(text)

            print("pypdf extraction complete.")
            return "\n".join(all_text)

        except Exception as e:
            print(f"pypdf error: {e}")
            return f"[pypdf error] {e}"

    else:
        print(f"Unsupported method: {method}")
        return "[error] Unsupported extraction method"
