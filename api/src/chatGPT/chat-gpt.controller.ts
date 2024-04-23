import { Controller, Get, Query, Res } from '@nestjs/common';
import { Response } from 'express';
import { ChatGptService } from './chat-gpt.service';

@Controller('chatgpt')
export class ChatGptController {
  constructor(private readonly chatGptService: ChatGptService) {}

  @Get()
  async getChatGptResponse(@Query('prompt') prompt: string, @Res() res: Response) {
    if (!prompt) {
      return res.status(400).send('Prompt is required');
    }

    try {
      const response = await this.chatGptService.getResponse(prompt);
      res.send({ response });
    } catch (error) {
      res.status(500).send('Error in getting response from ChatGPT');
    }
  }
}