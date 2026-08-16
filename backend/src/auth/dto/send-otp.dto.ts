import { IsString, Matches } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class SendOtpDto {
  @ApiProperty({
    description: 'Somali phone number (supports multiple formats)',
    example: '+252612345678',
    examples: {
      international: {
        value: '+252612345678',
        description: 'With +252 prefix',
      },
      noPlus: { value: '252612345678', description: 'Without + prefix' },
      local: { value: '0612345678', description: 'Local format with 0' },
      short: { value: '612345678', description: 'Short format (9 digits)' },
    },
  })
  @IsString()
  @Matches(/^(\+?252|0)?(61|63|68|90)\d{7}$/, {
    message:
      'Phone number must be a valid Somali number. Accepted formats: +252XXXXXXXXX, 252XXXXXXXXX, 0XXXXXXXXX, or 9-digit XXXXXXXX starting with 61, 63, 68, or 90',
  })
  phoneNumber: string;
}
