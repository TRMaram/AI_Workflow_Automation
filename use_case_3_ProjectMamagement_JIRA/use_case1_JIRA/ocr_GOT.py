from flask import Flask, request, jsonify
from PIL import Image
import numpy as np
import easyocr
import pytesseract
from transformers import TrOCRProcessor
from transformers import VisionEncoderDecoderModel
from transformers import AutoProcessor, AutoModelForImageTextToText
import io

app = Flask(__name__)

# Initialize the EasyOCR reader (add more languages if needed)
reader = easyocr.Reader(['en'])  # e.g., ['en', 'fr', 'ar']
model = VisionEncoderDecoderModel.from_pretrained("microsoft/trocr-base-handwritten")
model1 = AutoModelForImageTextToText.from_pretrained("stepfun-ai/GOT-OCR-2.0-hf")
        

@app.route('/ocr/GOT', methods=['POST'])
def GOT():
    if 'attachment_0' not in request.files:
        return jsonify({'error': 'No image file provided'}), 400

    image_file = request.files['attachment_0']

    try:
        image = Image.open(io.BytesIO(image_file.read())).convert('RGB')
        # Load model directly


        processor1 = AutoProcessor.from_pretrained("stepfun-ai/GOT-OCR-2.0-hf")
        inputs = processor1(image, return_tensors="pt")
        generate_ids = model1.generate(
            **inputs,
            do_sample=False,
            tokenizer=processor1.tokenizer,
            stop_strings="<|im_end|>",
            max_new_tokens=4096,
        )
        generated_text = processor1.decode(generate_ids[0, inputs["input_ids"].shape[1]:], skip_special_tokens=True)
        return jsonify({'text': ' '.join(generated_text)})

    except Exception as e:
        return jsonify({'error': str(e)}), 500
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
