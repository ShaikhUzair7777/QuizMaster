package com.quizmaster.service;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.*;

class SourceMaterialExtractorTest {

    @Test
    void extractsUtf8TextAndValidatesFileType() {
        String text = SourceMaterialExtractor.extract("notes.md", "text/markdown; charset=utf-8",
                "Cell structure".getBytes(StandardCharsets.UTF_8));

        assertEquals("Cell structure", text);
        assertThrows(IllegalArgumentException.class, () -> SourceMaterialExtractor.extract(
                "notes.exe", "application/octet-stream", "content".getBytes(StandardCharsets.UTF_8)));
    }

    @Test
    void rejectsEmptyAndInvalidUtf8Text() {
        assertThrows(IllegalArgumentException.class, () -> SourceMaterialExtractor.extract(
                "empty.txt", "text/plain", new byte[0]));
        assertThrows(IllegalArgumentException.class, () -> SourceMaterialExtractor.extract(
                "bad.txt", "text/plain", new byte[]{(byte) 0xc3, (byte) 0x28}));
        assertThrows(IllegalArgumentException.class, () -> SourceMaterialExtractor.extract(
                "large.pdf", "application/pdf",
                new byte[SourceMaterialExtractor.MAX_FILE_BYTES + 1]));
    }

    @Test
    void extractsTextFromPdfAndRejectsFakePdf() throws Exception {
        byte[] pdf;
        try (PDDocument document = new PDDocument();
             ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            PDPage page = new PDPage();
            document.addPage(page);
            try (PDPageContentStream stream = new PDPageContentStream(document, page)) {
                stream.beginText();
                stream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 12);
                stream.newLineAtOffset(40, 700);
                stream.showText("Mitochondria produce cellular energy");
                stream.endText();
            }
            document.save(output);
            pdf = output.toByteArray();
        }

        assertTrue(SourceMaterialExtractor.extract("notes.pdf", "application/pdf", pdf)
                .contains("Mitochondria produce cellular energy"));
        assertThrows(IllegalArgumentException.class, () -> SourceMaterialExtractor.extract(
                "notes.pdf", "application/pdf", "not a pdf".getBytes(StandardCharsets.UTF_8)));
    }
}
