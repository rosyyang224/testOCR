from docling.document_converter import DocumentConverter
from pypdf import PdfReader

def extract_text(path, method="docling"):
    print(f">>> extract_text() called with method: {method}")
    print(f">>> Target PDF path: {path}")

    if method == "docling":
        try:
            converter = DocumentConverter()
            result = converter.convert(path)
            # Tell it to insert your delimiter between pages
            markdown = result.document.export_to_markdown(page_break_placeholder="---PAGE_BREAK---")
            print("Docling markdown with page breaks generated.")
            return markdown
        except Exception as e:
            print(f"docling error: {e}")
            return f"[docling error] {e}"

    elif method == "pypdf":
        try:
            print("Loading PDF using pypdf...")
            reader = PdfReader(path)

            print(f"Number of pages: {len(reader.pages)}")
            pages = []

            for i, page in enumerate(reader.pages):
                print(f"Extracting page {i+1} using layout mode...")
                text = page.extract_text(
                    extraction_mode="layout",
                    layout_mode_strip_rotated=True  # can toggle this
                ) or ""
                pages.append(text)

            print("PyPDF extraction complete.")
            return "\n---PAGE_BREAK---\n".join(pages)

        except Exception as e:
            print(f"pypdf error: {e}")
            return f"[pypdf error] {e}"

    else:
        return "[error] Unsupported extraction method"
