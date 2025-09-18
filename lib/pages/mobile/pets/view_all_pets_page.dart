import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/models/user/pet_model.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/services/user/pet_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/widgets/user/pets/pet_card.dart';
import 'package:pawsense/core/widgets/user/pets/pet_search_bar.dart';
import 'package:pawsense/core/widgets/user/pets/pet_empty_state.dart';

class ViewAllPetsPage extends StatefulWidget {
  const ViewAllPetsPage({super.key});

  @override
  State<ViewAllPetsPage> createState() => _ViewAllPetsPageState();
}

class _ViewAllPetsPageState extends State<ViewAllPetsPage> {
  UserModel? _user;
  List<Pet> _pets = [];
  bool _loading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserAndPets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndPets() async {
    setState(() => _loading = true);
    
    try {
      final user = await AuthGuard.getCurrentUser();
      
      if (user != null) {
        setState(() {
          _user = user;
        });
        await _loadPets();
      } else {
        // Handle case where user is not authenticated
        if (mounted) {
          context.pop(); // Go back if no user
        }
      }
    } catch (e) {
      print('Error loading user: $e');
      // Handle authentication errors gracefully
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication error. Please sign in again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadPets() async {
    if (_user == null) return;
    
    try {
      List<Pet> pets;
      if (_searchQuery.isEmpty) {
        pets = await PetService.getUserPets(_user!.uid);
      } else {
        pets = await PetService.searchUserPets(_user!.uid, _searchQuery);
      }
      
      if (mounted) {
        setState(() {
          _pets = pets;
        });
      }
    } catch (e) {
      print('Error loading pets: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading pets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadPets();
  }

  void _navigateToAddPet() async {
    final result = await context.push('/add-pet');
    if (result == true) {
      _loadPets(); // Refresh the list
    }
  }

  void _navigateToEditPet(Pet pet) async {
    final result = await context.push('/edit-pet', extra: pet);
    if (result == true) {
      _loadPets(); // Refresh the list
    }
  }

  Future<void> _deletePet(Pet pet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pet'),
        content: Text('Are you sure you want to delete ${pet.petName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await PetService.deletePet(pet.id!);
      if (success) {
        _loadPets();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${pet.petName} deleted successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete pet')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'My Pets',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading ? _buildLoadingState() : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Search Bar with spacing
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: kMobileMarginHorizontal,
            vertical: kMobileSizedBoxMedium,
          ),
          child: PetSearchBar(
            initialQuery: _searchQuery,
            onChanged: _onSearchChanged,
          ),
        ),

        // Pets List
        Expanded(
          child: _pets.isEmpty ? _buildEmptyState() : _buildPetsList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: PetEmptyState(
        isSearching: _searchQuery.isNotEmpty,
      ),
    );
  }

  Widget _buildPetsList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: kMobileMarginHorizontal,
        vertical: kMobileSizedBoxSmall,
      ),
      itemCount: _pets.length,
      separatorBuilder: (context, index) => SizedBox(height: kMobileSizedBoxSmall),
      itemBuilder: (context, index) {
        final pet = _pets[index];
        return PetCard(
          pet: pet,
          onEdit: () => _navigateToEditPet(pet),
          onDelete: () => _deletePet(pet),
        );
      },
    );
  }
}
