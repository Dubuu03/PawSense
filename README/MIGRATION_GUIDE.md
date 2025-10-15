# Migration Guide: Local Assets to Cloudinary

## Overview
This guide explains how to migrate existing disease images from local assets to Cloudinary storage.

## Prerequisites

1. **Environment Variables Set**: Ensure your `.env` file has:
   ```env
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_UPLOAD_PRESET=your_upload_preset
   ```

2. **Backup Database**: Always backup your Firestore database before migration
   - Go to Firebase Console → Firestore Database → Export
   - Save the backup to a safe location

3. **Local Images Available**: Ensure all images exist in `assets/img/skin_diseases/`

## Migration Options

### Option 1: Automatic Migration (Recommended)
Use the provided migration script to automatically migrate all diseases.

### Option 2: Manual Migration (Safe for Testing)
Migrate diseases one-by-one through the admin UI.

### Option 3: Hybrid Approach
Migrate critical diseases manually first, then batch migrate the rest.

---

## Option 1: Automatic Migration Script

### Step 1: Create Migration Tool
Create a new file: `lib/pages/web/superadmin/disease_migration_tool.dart`

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/services/cloudinary/cloudinary_service.dart';
import 'dart:io';

class DiseaseMigrationTool extends StatefulWidget {
  const DiseaseMigrationTool({Key? key}) : super(key: key);

  @override
  State<DiseaseMigrationTool> createState() => _DiseaseMigrationToolState();
}

class _DiseaseMigrationToolState extends State<DiseaseMigrationTool> {
  final CloudinaryService _cloudinary = CloudinaryService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isMigrating = false;
  int _totalDiseases = 0;
  int _processed = 0;
  int _success = 0;
  int _failed = 0;
  int _skipped = 0;
  List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
    });
    print(message);
  }

  Future<void> _startMigration() async {
    if (_isMigrating) return;

    setState(() {
      _isMigrating = true;
      _processed = 0;
      _success = 0;
      _failed = 0;
      _skipped = 0;
      _logs.clear();
    });

    try {
      _addLog('🚀 Starting migration...');
      
      // Fetch all diseases
      final snapshot = await _firestore.collection('skinDiseases').get();
      setState(() {
        _totalDiseases = snapshot.docs.length;
      });
      
      _addLog('📋 Found $_totalDiseases diseases to process\n');

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final diseaseId = doc.id;
        final diseaseName = data['name'] ?? 'Unknown';
        final imageUrl = data['imageUrl'] ?? '';

        _addLog('Processing: $diseaseName');

        // Skip if already network URL
        if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
          _addLog('  ⏭️  Already using network URL, skipping...');
          setState(() {
            _skipped++;
            _processed++;
          });
          continue;
        }

        // Skip if no image
        if (imageUrl.isEmpty) {
          _addLog('  ⏭️  No image set, skipping...');
          setState(() {
            _skipped++;
            _processed++;
          });
          continue;
        }

        try {
          // Construct local file path
          final localPath = 'assets/img/skin_diseases/$imageUrl';
          final file = File(localPath);

          if (!await file.exists()) {
            _addLog('  ⚠️  File not found: $localPath');
            setState(() {
              _failed++;
              _processed++;
            });
            continue;
          }

          // Upload to Cloudinary
          _addLog('  ⬆️  Uploading to Cloudinary...');
          final cloudinaryUrl = await _cloudinary.uploadImageFromFile(
            localPath,
            folder: 'skin_diseases',
          );

          // Update Firestore
          await _firestore.collection('skinDiseases').doc(diseaseId).update({
            'imageUrl': cloudinaryUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          _addLog('  ✅ Successfully migrated!');
          _addLog('  📸 URL: $cloudinaryUrl\n');
          
          setState(() {
            _success++;
            _processed++;
          });

          // Add delay to avoid rate limiting
          await Future.delayed(Duration(seconds: 1));

        } catch (e) {
          _addLog('  ❌ Error: $e\n');
          setState(() {
            _failed++;
            _processed++;
          });
        }
      }

      _addLog('═' * 60);
      _addLog('✅ Migration Complete!');
      _addLog('Success: $_success | Skipped: $_skipped | Failed: $_failed');
      _addLog('═' * 60);

    } catch (e) {
      _addLog('❌ Fatal error: $e');
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Card
            Container(
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
                          'Make sure to backup your Firestore database before proceeding. This operation will modify all disease records.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Statistics Card
            if (_totalDiseases > 0)
              Container(
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
                      'Migration Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _totalDiseases > 0 ? _processed / _totalDiseases : 0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Total', _totalDiseases, Colors.blue),
                        _buildStatItem('Processed', _processed, Colors.grey),
                        _buildStatItem('Success', _success, Colors.green),
                        _buildStatItem('Skipped', _skipped, Colors.orange),
                        _buildStatItem('Failed', _failed, Colors.red),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Action Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _isMigrating ? null : _startMigration,
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
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Logs
            Expanded(
              child: Container(
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
                      child: ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
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
        ),
      ],
    );
  }
}
```

### Step 2: Add Route to Navigation
In your super admin navigation, add a button to access the migration tool:

```dart
// In your super admin dashboard or sidebar
ListTile(
  leading: const Icon(Icons.cloud_sync),
  title: const Text('Migrate to Cloudinary'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DiseaseMigrationTool()),
    );
  },
),
```

### Step 3: Run Migration
1. Navigate to Super Admin panel
2. Click "Migrate to Cloudinary"
3. Click "Start Migration" button
4. Wait for completion (monitor the logs)

---

## Option 2: Manual Migration (Safer)

For each disease:
1. Go to Diseases Management
2. Click "Edit" on a disease
3. Navigate to "Media" tab
4. Click "Upload Image to Cloudinary"
5. Select the same image file
6. Click "Update Disease"

**Pros:**
- Full control over each migration
- Can verify each image before updating
- No risk of batch failures

**Cons:**
- Time-consuming for many diseases
- Manual process

---

## Option 3: Script-Based Migration

Use the standalone migration script provided at:
`scripts/migrate_diseases_to_cloudinary.dart`

### Run from Terminal:
```bash
dart run scripts/migrate_diseases_to_cloudinary.dart
```

Or create a button in your app to run it programmatically.

---

## Post-Migration Verification

### Check Migration Status
After migration, verify all images are on Cloudinary:

1. Go to Diseases Management
2. Open each disease detail
3. Verify images load from Cloudinary URLs
4. Check that URLs start with `https://res.cloudinary.com/...`

### Verification Script
You can also use the verification function:

```dart
final migration = DiseaseMigrationScript();
await migration.verifyMigration();
```

This will print:
- ☁️ Number of Cloudinary URLs
- 📁 Number of local assets remaining
- 🔳 Number without images
- List of diseases still needing migration

---

## Rollback (Emergency Only)

If something goes wrong, you can restore from backup:

### From Firebase Console:
1. Go to Firestore Database
2. Click "Import" 
3. Select your backup file
4. Confirm import

### From Code:
```dart
// Only if you saved backup before migration
final migration = DiseaseMigrationScript();
await migration.rollbackMigration(backupMap);
```

---

## Troubleshooting

### Issue: "File not found" errors during migration
**Solution:** 
- Ensure images exist in `assets/img/skin_diseases/`
- Check file names match exactly (case-sensitive)
- Copy missing images to the folder

### Issue: "Cloudinary upload failed"
**Solution:**
- Check `.env` variables are correct
- Verify Cloudinary upload preset allows uploads
- Check internet connection
- Verify Cloudinary account limits

### Issue: Rate limiting errors
**Solution:**
- The script includes 1-second delays between uploads
- If still issues, increase delay in migration code
- Consider upgrading Cloudinary plan

### Issue: Some images not displaying after migration
**Solution:**
- Check Cloudinary URLs are valid HTTPS
- Verify images uploaded successfully
- Check Cloudinary console for uploaded files
- Try re-uploading specific failed images

---

## Best Practices

1. **Test First**: Migrate 1-2 diseases manually before batch migration
2. **Backup Always**: Never skip the backup step
3. **Off-Peak Hours**: Run migration during low-traffic times
4. **Monitor Logs**: Watch the migration logs for errors
5. **Verify Samples**: Check random diseases after migration
6. **Keep Backups**: Don't delete local images immediately
7. **Document Changes**: Note which diseases were migrated

---

## FAQ

**Q: Can I migrate in batches?**
A: Yes, modify the migration script to process specific disease IDs or date ranges.

**Q: What happens to old local images?**
A: They remain in your assets folder. You can delete them after verifying the migration.

**Q: Can I use both local and Cloudinary images?**
A: Yes! The app automatically detects and displays both types.

**Q: How long does migration take?**
A: ~2 seconds per disease (1 second upload + 1 second delay). For 50 diseases: ~2 minutes.

**Q: Can I cancel mid-migration?**
A: Yes, but already migrated diseases will keep their Cloudinary URLs. Just run again to continue.

**Q: What if I don't have the original image files?**
A: You'll need to re-upload images manually for those diseases.

---

## Support

If you encounter issues:
1. Check the logs in the migration tool
2. Verify environment variables
3. Test Cloudinary connection separately
4. Check Firebase console for errors
5. Review this guide's troubleshooting section

---

**Last Updated**: October 16, 2025  
**Version**: 1.0
