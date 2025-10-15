import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/services/cloudinary/cloudinary_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Interactive migration tool for moving disease images from local assets to Cloudinary
/// 
/// Usage: Add this page to your super admin navigation to access the migration tool
class DiseaseMigrationTool extends StatefulWidget {
  const DiseaseMigrationTool({Key? key}) : super(key: key);

  @override
  State<DiseaseMigrationTool> createState() => _DiseaseMigrationToolState();
}

class _DiseaseMigrationToolState extends State<DiseaseMigrationTool> {
  final CloudinaryService _cloudinary = CloudinaryService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isMigrating = false;
  bool _isAnalyzing = false;
  int _totalDiseases = 0;
  int _processed = 0;
  int _success = 0;
  int _failed = 0;
  int _skipped = 0;
  int _alreadyCloudinary = 0;
  int _needsMigration = 0;
  List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _analyzeCurrentState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
    });
    print(message);
    
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _analyzeCurrentState() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final snapshot = await _firestore.collection('skinDiseases').get();
      
      int cloudinaryCount = 0;
      int localCount = 0;
      int emptyCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final imageUrl = data['imageUrl'] ?? '';

        if (imageUrl.isEmpty) {
          emptyCount++;
        } else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
          cloudinaryCount++;
        } else {
          localCount++;
        }
      }

      setState(() {
        _totalDiseases = snapshot.docs.length;
        _alreadyCloudinary = cloudinaryCount;
        _needsMigration = localCount;
        _skipped = emptyCount;
        _isAnalyzing = false;
      });

      _addLog('📊 Analysis Complete:');
      _addLog('   Total Diseases: $_totalDiseases');
      _addLog('   ☁️  Already on Cloudinary: $cloudinaryCount');
      _addLog('   📁 Needs Migration: $localCount');
      _addLog('   🔳 No Image: $emptyCount\n');

    } catch (e) {
      _addLog('❌ Error analyzing: $e');
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _startMigration() async {
    if (_isMigrating) return;

    // Confirm before starting
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirm Migration'),
        content: Text(
          'This will migrate $_needsMigration disease images to Cloudinary.\n\n'
          '✅ Already migrated: $_alreadyCloudinary will be skipped\n'
          '📁 Images to upload: $_needsMigration\n\n'
          'Make sure you have backed up your database first!\n\n'
          'Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
            ),
            child: const Text('Start Migration'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isMigrating = true;
      _processed = 0;
      _success = 0;
      _failed = 0;
      _logs.clear();
    });

    try {
      _addLog('🚀 Starting migration...\n');
      
      // Fetch all diseases
      final snapshot = await _firestore.collection('skinDiseases').get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final diseaseId = doc.id;
        final diseaseName = data['name'] ?? 'Unknown';
        final imageUrl = data['imageUrl'] ?? '';

        _addLog('📝 Processing: $diseaseName');

        // Skip if already network URL
        if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
          _addLog('   ⏭️  Already using Cloudinary URL');
          setState(() {
            _processed++;
          });
          continue;
        }

        // Skip if no image
        if (imageUrl.isEmpty) {
          _addLog('   ⏭️  No image set');
          setState(() {
            _processed++;
          });
          continue;
        }

        try {
          // Check if running on web
          if (kIsWeb) {
            _addLog('   ⚠️  Cannot access local files on web platform');
            _addLog('   💡 Please migrate this disease manually through the edit screen');
            setState(() {
              _failed++;
              _processed++;
            });
            continue;
          }

          // Construct local file path
          final localPath = 'assets/img/skin_diseases/$imageUrl';
          final file = File(localPath);

          if (!await file.exists()) {
            _addLog('   ⚠️  File not found: $localPath');
            _addLog('   💡 Please upload image manually');
            setState(() {
              _failed++;
              _processed++;
            });
            continue;
          }

          // Upload to Cloudinary
          _addLog('   ⬆️  Uploading to Cloudinary...');
          final cloudinaryUrl = await _cloudinary.uploadImageFromFile(
            localPath,
            folder: 'skin_diseases',
          );

          // Update Firestore
          await _firestore.collection('skinDiseases').doc(diseaseId).update({
            'imageUrl': cloudinaryUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          _addLog('   ✅ Success!');
          _addLog('   📸 URL: $cloudinaryUrl\n');
          
          setState(() {
            _success++;
            _processed++;
          });

          // Add delay to avoid rate limiting
          await Future.delayed(const Duration(seconds: 1));

        } catch (e) {
          _addLog('   ❌ Error: $e\n');
          setState(() {
            _failed++;
            _processed++;
          });
        }
      }

      _addLog('═' * 60);
      _addLog('🎉 Migration Complete!');
      _addLog('   ✅ Success: $_success');
      _addLog('   ⏭️  Skipped: ${_alreadyCloudinary + _skipped}');
      _addLog('   ❌ Failed: $_failed');
      _addLog('═' * 60);

      // Show completion dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Migration Complete'),
            content: Text(
              'Successfully migrated $_success images to Cloudinary!\n\n'
              'Failed: $_failed\n'
              'Skipped: ${_alreadyCloudinary + _skipped}\n\n'
              'Check the logs for details.'
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      _addLog('❌ Fatal error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Disease Image Migration to Cloudinary'),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
      ),
      body: _isAnalyzing
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning Card
                  _buildWarningCard(),

                  const SizedBox(height: 24),

                  // Statistics Card
                  _buildStatisticsCard(),

                  const SizedBox(height: 24),

                  // Progress Section
                  if (_isMigrating || _processed > 0)
                    _buildProgressSection(),

                  if (_isMigrating || _processed > 0)
                    const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(),

                  const SizedBox(height: 24),

                  // Logs
                  Expanded(child: _buildLogsSection()),
                ],
              ),
            ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ Important: Backup First!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Make sure to backup your Firestore database before proceeding. This operation will modify disease records.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade800,
                  ),
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 8),
                  Text(
                    '🌐 Web Platform Note: Automatic migration won\'t work on web. Use manual migration for each disease instead.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Current Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', _totalDiseases, Icons.storage, Colors.blue),
              _buildStatItem('On Cloudinary', _alreadyCloudinary, Icons.cloud_done, Colors.green),
              _buildStatItem('Needs Migration', _needsMigration, Icons.cloud_upload, Colors.orange),
              _buildStatItem('No Image', _skipped, Icons.image_not_supported, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Migration Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                '$_processed / $_needsMigration',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _needsMigration > 0 ? _processed / _needsMigration : 0,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressStat('✅ Success', _success, Colors.green),
              _buildProgressStat('❌ Failed', _failed, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_isMigrating) ...[
          ElevatedButton.icon(
            onPressed: _analyzeCurrentState,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Analysis'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
          const SizedBox(width: 16),
        ],
        ElevatedButton.icon(
          onPressed: _isMigrating || _needsMigration == 0 || kIsWeb ? null : _startMigration,
          icon: _isMigrating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.cloud_upload),
          label: Text(_isMigrating ? 'Migrating...' : 'Start Migration'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildLogsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal, color: Colors.green.shade400, size: 20),
              const SizedBox(width: 8),
              Text(
                'Migration Log',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Text(
                      'Logs will appear here during migration...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: SelectableText(
                          _logs[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Courier',
                            color: Colors.green.shade300,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressStat(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
