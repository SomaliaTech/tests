import {
  IsString,
  IsOptional,
  IsBoolean,
  IsPhoneNumber,
  MaxLength,
  MinLength,
} from 'class-validator';

export class AddressDto {
  @IsString()
  @MaxLength(50)
  label: string; // 'Home', 'Office', 'Other'

  @IsString()
  @MaxLength(500)
  fullAddress: string;

  @IsString()
  @IsPhoneNumber()
  phoneNumber: string;

  @IsBoolean()
  @IsOptional()
  isDefault?: boolean;
}

export class UpdateAddressDto {
  @IsString()
  @MaxLength(50)
  @IsOptional()
  label?: string;

  @IsString()
  @MaxLength(500)
  @IsOptional()
  fullAddress?: string;

  @IsString()
  @IsPhoneNumber()
  @IsOptional()
  phoneNumber?: string;

  @IsBoolean()
  @IsOptional()
  isDefault?: boolean;
}
