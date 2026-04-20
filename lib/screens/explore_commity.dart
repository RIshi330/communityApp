// explories commity screen .dart

import 'package:flutter/material.dart';

class ExploreCommunitiesProScreen extends StatefulWidget {
  const ExploreCommunitiesProScreen({super.key});

  @override
  State<ExploreCommunitiesProScreen> createState() =>
      _ExploreCommunitiesProScreenState();
}

class _ExploreCommunitiesProScreenState
    extends State<ExploreCommunitiesProScreen> {

  String search = "";
  String selectedFilter = "All";
  String sortBy = "Most Popular";

  bool showVerifiedOnly = false;
  bool showFreeOnly = false;

  final filters = [
    "All",
    "Free",
    "Paid",
    "Verified",
    "Trending",
  ];

  final List<Map<String, dynamic>> communities = [
    {
      "name": "Startup Founders Hub",
      "members": 2480,
      "rating": 4.9,
      "verified": true,
      "paid": true,
      "inviteOnly": false,
      "price": 499,
      "activity": "High",
      "tags": ["Startups", "Funding"],
      "featured": true,
      "trending": true,
      "seatsLeft": 23,
      "mutual": 12,
    },
    {
      "name": "Flutter Dev Circle",
      "members": 1820,
      "rating": 4.7,
      "verified": true,
      "paid": false,
      "inviteOnly": false,
      "activity": "Medium",
      "tags": ["Flutter", "Tech"],
      "featured": false,
      "trending": false,
      "seatsLeft": 80,
      "mutual": 5,
    },
    {
      "name": "Women Entrepreneurs",
      "members": 920,
      "rating": 4.8,
      "verified": false,
      "paid": false,
      "inviteOnly": true,
      "activity": "New",
      "tags": ["Business", "Women"],
      "featured": false,
      "trending": true,
      "seatsLeft": 12,
      "mutual": 3,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    int crossAxisCount = 1;
    if (width > 1200) crossAxisCount = 4;
    else if (width > 900) crossAxisCount = 3;
    else if (width > 600) crossAxisCount = 2;

    List<Map<String, dynamic>> filtered =
        communities.where((c) {
      if (showVerifiedOnly && !c["verified"])
        return false;
      if (showFreeOnly && c["paid"])
        return false;
      if (search.isNotEmpty &&
          !c["name"]
              .toLowerCase()
              .contains(search.toLowerCase()))
        return false;
      return true;
    }).toList();

    if (sortBy == "Highest Rated") {
      filtered.sort((a, b) =>
          b["rating"].compareTo(a["rating"]));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore Communities"),
        actions: [
          IconButton(
              onPressed: () => _openFilters(),
              icon: const Icon(Icons.filter_alt))
        ],
      ),
      body: Column(
        children: [

          /// SEARCH
          Padding(
            padding:
                const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText:
                    "Search communities...",
                prefixIcon:
                    Icon(Icons.search),
                border:
                    OutlineInputBorder(),
              ),
              onChanged: (v) =>
                  setState(() => search = v),
            ),
          ),

          /// SORT
          Padding(
            padding:
                const EdgeInsets.symmetric(
                    horizontal: 16),
            child: DropdownButtonFormField(
              value: sortBy,
              items: [
                "Most Popular",
                "Highest Rated",
                "Most Active",
                "Newest",
                "Price Low → High"
              ]
                  .map((e) =>
                      DropdownMenuItem(
                          value: e,
                          child: Text(e)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => sortBy = v!),
            ),
          ),

          const SizedBox(height: 16),

          /// GRID
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: GridView.builder(
                itemCount: filtered.length,
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (_, i) =>
                    _communityCard(
                        filtered[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Advanced Filters",
                style: TextStyle(
                    fontWeight:
                        FontWeight.bold)),
            SwitchListTile(
              title:
                  const Text("Verified Only"),
              value: showVerifiedOnly,
              onChanged: (v) =>
                  setState(() =>
                      showVerifiedOnly = v),
            ),
            SwitchListTile(
              title:
                  const Text("Free Communities"),
              value: showFreeOnly,
              onChanged: (v) =>
                  setState(() =>
                      showFreeOnly = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _communityCard(
      Map<String, dynamic> c) {
    bool saved = false;
    String state = "visitor";

    return StatefulBuilder(
      builder: (context, setInner) {
        Widget actionButton() {
          if (state == "member") {
            return ElevatedButton(
              onPressed: () {},
              child: const Text("Enter"),
            );
          }

          if (c["inviteOnly"]) {
            return ElevatedButton(
              onPressed: () =>
                  setInner(() =>
                      state = "pending"),
              child: const Text("Request"),
            );
          }

          if (c["paid"]) {
            return ElevatedButton(
              onPressed: () =>
                  setInner(() =>
                      state = "member"),
              child: Text(
                  "Pay ₹${c["price"]}"),
            );
          }

          return ElevatedButton(
            onPressed: () =>
                setInner(() =>
                    state = "member"),
            child:
                const Text("Join"),
          );
        }

        return Stack(
          children: [
            Container(
              padding:
                  const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                    color:
                        Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  /// HEADER
                  Row(
                    children: [
                      const CircleAvatar(
                          child: Icon(
                              Icons.groups)),
                      const SizedBox(
                          width: 10),
                      Expanded(
                        child: Text(
                          c["name"],
                          style:
                              const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold),
                        ),
                      ),
                      if (c["verified"])
                        const Icon(
                            Icons.verified,
                            color:
                                Colors.blue,
                            size: 18),
                    ],
                  ),

                  const SizedBox(
                      height: 8),

                  /// RATING + MEMBERS
                  Row(
                    children: [
                      const Icon(
                          Icons.star,
                          size: 16,
                          color:
                              Colors.orange),
                      Text(
                          " ${c["rating"]}"),
                      const SizedBox(
                          width: 10),
                      Text(
                          "${c["members"]} members"),
                    ],
                  ),

                  const SizedBox(
                      height: 6),

                  /// TRENDING
                  if (c["trending"])
                    const Row(
                      children: [
                        Icon(Icons.local_fire_department,
                            color: Colors.red,
                            size: 16),
                        SizedBox(width: 4),
                        Text("Trending"),
                      ],
                    ),

                  const SizedBox(
                      height: 6),

                  /// TAGS
                  Wrap(
                    spacing: 6,
                    children:
                        (c["tags"]
                                as List)
                            .map((t) =>
                                Chip(
                                  label:
                                      Text(t),
                                ))
                            .toList(),
                  ),

                  const Spacer(),

                  /// MUTUAL
                  Text(
                      "${c["mutual"]} mutual connections"),

                  const SizedBox(
                      height: 6),

                  /// URGENCY
                  if (c["seatsLeft"] < 30)
                    Text(
                        "Only ${c["seatsLeft"]} seats left",
                        style: const TextStyle(
                            color: Colors.red)),

                  const SizedBox(
                      height: 8),

                  actionButton(),
                ],
              ),
            ),

            /// FEATURED RIBBON
            if (c["featured"])
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                          horizontal:
                              8,
                          vertical:
                              4),
                  decoration:
                      const BoxDecoration(
                    color:
                        Colors.deepPurple,
                    borderRadius:
                        BorderRadius.only(
                            topLeft:
                                Radius
                                    .circular(
                                        16),
                            bottomRight:
                                Radius
                                    .circular(
                                        16)),
                  ),
                  child: const Text(
                      "FEATURED",
                      style: TextStyle(
                          color:
                              Colors.white,
                          fontSize: 10)),
                ),
              ),

            /// SAVE
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  saved
                      ? Icons
                          .bookmark
                      : Icons
                          .bookmark_border,
                ),
                onPressed: () =>
                    setInner(() =>
                        saved =
                            !saved),
              ),
            )
          ],
        );
      },
    );
  }
}
