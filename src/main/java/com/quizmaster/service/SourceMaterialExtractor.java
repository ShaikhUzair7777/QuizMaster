package com.quizmaster.service;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.text.PDFTextStripper;

import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.Locale;
import java.util.Set;

/** Validates and extracts supported study material without persisting source files. */
public final class SourceMaterialExtractor {

    public static final int MAX_FILE_BYTES = 10 * 1024 * 1024;
    private static final int MAX_TEXT_FILE_BYTES = 100 * 1024;
    private static final int MAX_CSV_FILE_BYTES = 200 * 1024;

    private SourceMaterialExtractor() {}

    public static String extract(String fileName, String contentType, byte[] bytes) {
        if (fileName == null || fileName.contains("/") || fileName.contains("\\")
                || fileName.contains("..") || bytes == null) {
            throw new IllegalArgumentException("Choose a valid source file.");
        }
        if (bytes.length > MAX_FILE_BYTES) {
            throw new IllegalArgumentException("Source files must be no larger than 10 MB.");
        }
        String extension = fileName.substring(fileName.lastIndexOf('.') + 1)
                .toLowerCase(Locale.ROOT);
        String mimeType = contentType == null ? ""
                : contentType.toLowerCase(Locale.ROOT).split(";", 2)[0].trim();

        if ("pdf".equals(extension)) {
            if (!"application/pdf".equals(mimeType) || !startsWith(bytes, "%PDF-")) {
                throw new IllegalArgumentException(
                        "The selected PDF is invalid or has an unexpected file type.");
            }
            try (var document = Loader.loadPDF(bytes)) {
                String text = new PDFTextStripper().getText(document);
                if (text == null || text.isBlank()) {
                    throw new InvalidSourceException(
                            "No readable text was found in this PDF. Scanned/image-only PDFs need OCR, which is not enabled.");
                }
                if (text.length() > QuizGenerationService.MAX_SOURCE_LENGTH) {
                    throw new InvalidSourceException("Extracted text is too long. Use a shorter PDF.");
                }
                return text;
            } catch (InvalidSourceException ex) {
                throw ex;
            } catch (Exception ex) {
                throw new IllegalArgumentException(
                        "Could not read this PDF. Check that it is not corrupt or encrypted.");
            }
        }

        int maxTextFileBytes = "csv".equals(extension)
                ? MAX_CSV_FILE_BYTES : MAX_TEXT_FILE_BYTES;
        if (!Set.of("txt", "md", "csv").contains(extension)
                || bytes.length > maxTextFileBytes
                || !Set.of("text/plain", "text/markdown", "text/csv").contains(mimeType)) {
            throw new IllegalArgumentException(
                    "Upload a text or Markdown file up to 100 KB, a CSV file up to 200 KB, "
                            + "or a PDF file up to 10 MB.");
        }
        try {
            String text = StandardCharsets.UTF_8.newDecoder()
                    .onMalformedInput(CodingErrorAction.REPORT)
                    .onUnmappableCharacter(CodingErrorAction.REPORT)
                    .decode(ByteBuffer.wrap(bytes)).toString();
            if (text.isBlank() || text.indexOf('\0') >= 0
                    || text.length() > QuizGenerationService.MAX_SOURCE_LENGTH) {
                throw new IllegalArgumentException("The selected text file is empty or too long.");
            }
            return text;
        } catch (CharacterCodingException ex) {
            throw new IllegalArgumentException("Text files must use UTF-8 encoding.");
        }
    }

    private static boolean startsWith(byte[] bytes, String prefix) {
        byte[] expected = prefix.getBytes(StandardCharsets.US_ASCII);
        if (bytes.length < expected.length) return false;
        for (int i = 0; i < expected.length; i++) {
            if (bytes[i] != expected[i]) return false;
        }
        return true;
    }

    private static final class InvalidSourceException extends IllegalArgumentException {
        private InvalidSourceException(String message) {
            super(message);
        }
    }
}
