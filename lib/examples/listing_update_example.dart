import 'package:flutter/material.dart';
import '../presentation/screens/list/edit_listing_screen.dart';

/// Example usage of the updated EditListingScreen with API integration
class ListingUpdateExample extends StatelessWidget {
  const ListingUpdateExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing Update Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Listing Update API Integration',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'The EditListingScreen now includes:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text('• Real API calls for updating listings'),
            const Text('• Proper error handling and loading states'),
            const Text('• Dynamic listing states from API'),
            const Text('• Form validation'),
            const Text('• Success/error feedback'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Example: Navigate to edit listing screen with listing ID
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditListingScreen(
                      listingId: 'example-listing-id',
                      onListingUpdated: (updatedListing) {
                        // Handle listing update
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Listing updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      onListingDeleted: (listingId) {
                        // Handle listing deletion
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Listing deleted successfully!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              child: const Text('Test Edit Listing Screen'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Example: Navigate to edit listing screen with listing ID
                // The EditListingScreen will fetch the listing data from API using the ID
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditListingScreen(
                      listingId: 'example-listing-id',
                      onListingUpdated: (updatedListing) {
                        // Handle listing update
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Listing updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      onListingDeleted: (listingId) {
                        // Handle listing deletion
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Listing deleted successfully!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              child: const Text('Test with Example Listing ID'),
            ),
          ],
        ),
      ),
    );
  }
}

/// API Configuration Summary
/// 
/// The updated EditListingScreen now uses the following API endpoints:
/// 
/// 1. GET /api/zecorner/listing/{id} - Get listing detail
/// 2. POST /api/zecorner/listing/{id} - Update listing
/// 3. POST /api/zecorner/listing/{id}/state - Update listing state
/// 4. GET /api/zecorner/refListingStates - Get listing states
/// 
/// Headers used:
/// - X-SESSION: User JWT token
/// - X-API-KEY: ed017c68-24ca-4239-ae68-0fa041391855
/// - X-APP-ID: zecorner
/// - Content-Type: application/json
/// - Accept: application/json
/// 
/// Features implemented:
/// - Real-time form validation
/// - Loading states during API calls
/// - Error handling with user-friendly messages
/// - Success feedback
/// - Dynamic listing states from API
/// - Proper data mapping between models
