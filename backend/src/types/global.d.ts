// Add these interfaces below your imports to satisfy strict ESLint rules
interface ProductCreateShape {
  name: string;
  slug?: string;
  description?: string;
  price: number;
  stock?: number;
  isActive?: boolean;
  categoryId: string;
  imageUrls?: string[];
}

interface ProductUpdateShape {
  name?: string;
  slug?: string;
  description?: string;
  price?: number;
  stock?: number;
  isActive?: boolean;
  categoryId?: string;
}
