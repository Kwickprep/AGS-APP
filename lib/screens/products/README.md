# Product Listing Page

This module implements a complete product listing page with full API integration.

## Files Created

1. **`product_screen.dart`** - Main product listing UI
2. **`../../models/product_model.dart`** - Product data models
3. **`../../services/product_service.dart`** - API service layer

## Features

### Display Features
- ✅ Product image thumbnails (60x60) with loading states
- ✅ Product name with description
- ✅ Price display with formatting
- ✅ Price range column
- ✅ Category badges (color-coded)
- ✅ Brand information
- ✅ AOP (Actual Operating Price) column
- ✅ Landed cost column
- ✅ Tags count badge (blue)
- ✅ Themes count badge (purple)
- ✅ Status badge (Active/Inactive)
- ✅ Created by column
- ✅ Created date column
- ✅ Serial number column

### Interactive Features
- ✅ Search functionality with debounce
- ✅ Sorting on all relevant columns
- ✅ Status filter (All/Active/Inactive)
- ✅ Price range filter (5 ranges)
- ✅ Pagination with page size options
- ✅ Total count display
- ✅ Edit and Delete actions
- ✅ Empty state with icon and message
- ✅ Loading state
- ✅ Error state

## API Integration

### Endpoint
```
GET https://server.allgiftstudio.com/api/products
```

### Parameters
- `page` - Page number (default: 1)
- `take` - Items per page (default: 20)
- `search` - Search query string
- `sortBy` - Field to sort by (default: 'createdAt')
- `sortOrder` - Sort direction: 'asc' or 'desc' (default: 'desc')
- `filters` - Filter criteria
- `isPageLayout` - Boolean flag (default: true)

### Service Methods

```dart
// Get paginated products
await productService.getProducts(
  page: 1,
  take: 20,
  search: 'query',
  sortBy: 'name',
  sortOrder: 'asc',
);

// Get single product
await productService.getProduct(productId);

// Create product
await productService.createProduct(data);

// Update product
await productService.updateProduct(productId, data);

// Delete product
await productService.deleteProduct(productId);

// Search products
await productService.searchProducts('query');
```

## Usage

### Navigate to Products
```dart
Navigator.pushNamed(context, AppRoutes.products);
```

### Access from Drawer
The "Products" menu item is available in the app drawer with an inventory icon.

## Data Model

The `ProductModel` includes:
- Basic info: id, name, description, image
- Pricing: price, priceValue, priceRange, priceRangeMin, priceRangeMax
- Categorization: category, brand, tags, themes
- Metadata: aop, landed, createdBy, createdAt, updatedAt, isActive
- Related objects: images[], categories[], tags[], themes[], creator, updater
- Actions: actions[] for UI operations

## Filters

### Status Filter
- All
- Active
- Inactive

### Price Range Filter
- All
- ₹0 - ₹500
- ₹501 - ₹1,000
- ₹1,001 - ₹2,500
- ₹2,501 - ₹5,000
- ₹5,001 & above

## Sorting

Sortable columns:
- Name
- Price
- Category
- Brand
- AOP
- Landed
- Status
- Created By
- Created Date

## Dependencies

- `cached_network_image: ^3.4.1` - For image caching and loading
- Uses existing generic widgets for consistency

## Notes

- Images are cached for better performance
- Filters and sorting are applied client-side for speed
- Pagination is handled server-side
- Search has a 500ms debounce to reduce API calls
- Empty states show helpful messages
- All API errors are caught and displayed to the user
