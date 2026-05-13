class OurPartner {
  final int id;
  final String name;
  final String avatarUrl;

  OurPartner({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });

  factory OurPartner.fromJson(Map<String, dynamic> json) {
    return OurPartner(
      id: json['id'],
      name: json['name'] ?? 'Unknown Partner',
      avatarUrl: json['avatar_url'] ?? "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=150&q=80",
    );
  }
}

// Dummy Data
final List<OurPartner> dummyPartners = [
  OurPartner(
    id: 1,
    name: "EcoMart",
    avatarUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=150&q=80",
  ),
  OurPartner(
    id: 2,
    name: "Fresh Bakery",
    avatarUrl: "https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=150&q=80",
  ),
  OurPartner(
    id: 3,
    name: "Green Grocer",
    avatarUrl: "https://images.unsplash.com/photo-1578916171728-46686eac8d58?auto=format&fit=crop&w=150&q=80",
  ),
  OurPartner(
    id: 4,
    name: "SaveFood Cafe",
    avatarUrl: "https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=150&q=80",
  ),
];
