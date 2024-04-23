import { Injectable } from "@nestjs/common";
import axios from "axios";

@Injectable()
export class ChatGptService {
  private readonly chatGptUrl = 'https://api.openai.com/v1/engines/davinci-codex/completions'; // Replace with the actual ChatGPT API URL

  async getResponse(prompt: string): Promise<string> {
    try {
      const response = await axios.post(this.chatGptUrl, {
        prompt: prompt,
        max_tokens: 150, // Customize as needed
      }, {
        headers: {
          'Authorization': `Bearer ${process.env.CHATGPT_API_KEY}`, // Ensure to set the API key in your environment variables
          'Content-Type': 'application/json',
        },
      });

      return response.data.choices[0].text.trim();
    } catch (error) {
      console.error('Error communicating with ChatGPT:', error);
      throw new Error('Failed to get response from ChatGPT');
    }
  }
}