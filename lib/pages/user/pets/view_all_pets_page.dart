import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/models/user/pet_model.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/services/user/pet_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

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
    try {
      final user = await AuthGuard.getCurrentUser();
      if (user != null) {
        setState(() {
          _user = user;
        });
        await _loadPets();
      }
    } catch (e) {
      print('Error loading user: $e');
    } finally {
      setState(() {
        _loading = false;
      });
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
      
      setState(() {
        _pets = pets;
      });
    } catch (e) {
      print('Error loading pets: $e');
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
        // Search Bar
        Container(
          margin: const EdgeInsets.all(kMobileMarginHorizontal),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search pets by name, breed, or type...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No pets added yet' : 'No pets found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'Add your first pet using the + button'
                : 'Try adjusting your search terms',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPetsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
      itemCount: _pets.length,
      itemBuilder: (context, index) {
        final pet = _pets[index];
        return _buildPetCard(pet);
      },
    );
  }

  Widget _buildPetCard(Pet pet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: kMobileCardShadow,
      ),
      child: Row(
        children: [
          // Pet Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: pet.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      pet.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPetIcon(pet.petType);
                      },
                    ),
                  )
                : _buildPetIcon(pet.petType),
          ),
          
          const SizedBox(width: 16),
          
          // Pet Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.petName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pet.petType} • ${pet.breed}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pet.ageString} • ${pet.weightString}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _navigateToEditPet(pet);
                  break;
                case 'delete':
                  _deletePet(pet);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetIcon(String petType) {
    IconData icon;
    switch (petType.toLowerCase()) {
      case 'dog':
        icon = Icons.pets;
        break;
      case 'cat':
        icon = Icons.pets;
        break;
      default:
        icon = Icons.pets;
    }

    return Icon(
      icon,
      size: 24,
      color: AppColors.primary,
    );
  }
}
