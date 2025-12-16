// For demo only
import 'package:shop/constants.dart';

class ProductModel {
  final String id; // Unique identifier for wishlist and comparison
  final String image, brandName, title;
  final double price;
  final double? priceAfetDiscount;
  final int? dicountpercent;
  final double? rating; // For comparison feature
  final int? reviewCount; // For comparison feature
  final String? description; // For comparison feature

  ProductModel({
    required this.id,
    required this.image,
    required this.brandName,
    required this.title,
    required this.price,
    this.priceAfetDiscount,
    this.dicountpercent,
    this.rating,
    this.reviewCount,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image': image,
      'brandName': brandName,
      'title': title,
      'price': price,
      'priceAfetDiscount': priceAfetDiscount,
      'dicountpercent': dicountpercent,
      'rating': rating,
      'reviewCount': reviewCount,
      'description': description,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      image: map['image'] as String,
      brandName: map['brandName'] as String,
      title: map['title'] as String,
      price: (map['price'] is int) ? (map['price'] as int).toDouble() : (map['price'] as double),
      priceAfetDiscount: map['priceAfetDiscount'] != null
          ? (map['priceAfetDiscount'] is int
              ? (map['priceAfetDiscount'] as int).toDouble()
              : (map['priceAfetDiscount'] as double))
          : null,
      dicountpercent: map['dicountpercent'] as int?,
      rating: map['rating'] != null
          ? (map['rating'] is int ? (map['rating'] as int).toDouble() : (map['rating'] as double))
          : null,
      reviewCount: map['reviewCount'] as int?,
      description: map['description'] as String?,
    );
  }
}

List<ProductModel> demoPopularProducts = [
  ProductModel(
    id: 'prod_1',
    image: productDemoImg1,
    title: "Mountain Warehouse for Women",
    brandName: "Lipsy london",
    price: 540,
    priceAfetDiscount: 420,
    dicountpercent: 20,
    rating: 4.5,
    reviewCount: 128,
  ),
  ProductModel(
    id: 'prod_2',
    image: productDemoImg4,
    title: "Mountain Beta Warehouse",
    brandName: "Lipsy london",
    price: 800,
    rating: 4.0,
    reviewCount: 75,
  ),
  ProductModel(
    id: 'prod_3',
    image: productDemoImg5,
    title: "FS - Nike Air Max 270 Really React",
    brandName: "Lipsy london",
    price: 650.62,
    priceAfetDiscount: 390.36,
    dicountpercent: 40,
    rating: 4.7,
    reviewCount: 256,
  ),
  ProductModel(
    id: 'prod_4',
    image: productDemoImg6,
    title: "Green Poplin Ruched Front",
    brandName: "Lipsy london",
    price: 1264,
    priceAfetDiscount: 1200.8,
    dicountpercent: 5,
    rating: 4.2,
    reviewCount: 92,
  ),
  ProductModel(
    id: 'prod_5',
    image: "https://i.imgur.com/tXyOMMG.png",
    title: "Green Poplin Ruched Front",
    brandName: "Lipsy london",
    price: 650.62,
    priceAfetDiscount: 390.36,
    dicountpercent: 40,
    rating: 4.3,
    reviewCount: 145,
  ),
  ProductModel(
    id: 'prod_6',
    image: "https://i.imgur.com/h2LqppX.png",
    title: "white satin corset top",
    brandName: "Lipsy london",
    price: 1264,
    priceAfetDiscount: 1200.8,
    dicountpercent: 5,
    rating: 4.6,
    reviewCount: 189,
  ),
];
List<ProductModel> demoFlashSaleProducts = [
  ProductModel(
    id: 'flash_1',
    image: productDemoImg5,
    title: "FS - Nike Air Max 270 Really React",
    brandName: "Lipsy london",
    price: 650.62,
    priceAfetDiscount: 390.36,
    dicountpercent: 40,
    rating: 4.7,
    reviewCount: 256,
  ),
  ProductModel(
    id: 'flash_2',
    image: productDemoImg6,
    title: "Green Poplin Ruched Front",
    brandName: "Lipsy london",
    price: 1264,
    priceAfetDiscount: 1200.8,
    dicountpercent: 5,
    rating: 4.2,
    reviewCount: 92,
  ),
  ProductModel(
    id: 'flash_3',
    image: productDemoImg4,
    title: "Mountain Beta Warehouse",
    brandName: "Lipsy london",
    price: 800,
    priceAfetDiscount: 680,
    dicountpercent: 15,
    rating: 4.0,
    reviewCount: 75,
  ),
];
List<ProductModel> demoBestSellersProducts = [
  ProductModel(
    id: 'best_1',
    image: "https://i.imgur.com/tXyOMMG.png",
    title: "Green Poplin Ruched Front",
    brandName: "Lipsy london",
    price: 650.62,
    priceAfetDiscount: 390.36,
    dicountpercent: 40,
    rating: 4.3,
    reviewCount: 145,
  ),
  ProductModel(
    id: 'best_2',
    image: "https://i.imgur.com/h2LqppX.png",
    title: "white satin corset top",
    brandName: "Lipsy london",
    price: 1264,
    priceAfetDiscount: 1200.8,
    dicountpercent: 5,
    rating: 4.6,
    reviewCount: 189,
  ),
  ProductModel(
    id: 'best_3',
    image: productDemoImg4,
    title: "Mountain Beta Warehouse",
    brandName: "Lipsy london",
    price: 800,
    priceAfetDiscount: 680,
    dicountpercent: 15,
    rating: 4.0,
    reviewCount: 75,
  ),
];
List<ProductModel> kidsProducts = [
  ProductModel(
    id: 'kids_1',
    image: "https://i.imgur.com/dbbT6PA.png",
    title: "Green Poplin Ruched Front",
    brandName: "Lipsy london",
    price: 650.62,
    priceAfetDiscount: 590.36,
    dicountpercent: 24,
    rating: 4.4,
    reviewCount: 110,
  ),
  ProductModel(
    id: 'kids_2',
    image: "https://i.imgur.com/7fSxC7k.png",
    title: "Printed Sleeveless Tiered Swing Dress",
    brandName: "Lipsy london",
    price: 650.62,
    rating: 4.1,
    reviewCount: 65,
  ),
  ProductModel(
    id: 'kids_3',
    image: "https://i.imgur.com/pXnYE9Q.png",
    title: "Ruffle-Sleeve Ponte-Knit Sheath ",
    brandName: "Lipsy london",
    price: 400,
    rating: 3.9,
    reviewCount: 45,
  ),
  ProductModel(
    id: 'kids_4',
    image: "https://i.imgur.com/V1MXgfa.png",
    title: "Green Mountain Beta Warehouse",
    brandName: "Lipsy london",
    price: 400,
    priceAfetDiscount: 360,
    dicountpercent: 20,
    rating: 4.2,
    reviewCount: 82,
  ),
  ProductModel(
    id: 'kids_5',
    image: "https://i.imgur.com/8gvE5Ss.png",
    title: "Printed Sleeveless Tiered Swing Dress",
    brandName: "Lipsy london",
    price: 654,
    rating: 4.0,
    reviewCount: 58,
  ),
  ProductModel(
    id: 'kids_6',
    image: "https://i.imgur.com/cBvB5YB.png",
    title: "Mountain Beta Warehouse",
    brandName: "Lipsy london",
    price: 250,
    rating: 3.8,
    reviewCount: 35,
  ),
];
