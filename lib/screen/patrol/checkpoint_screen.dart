import 'package:flutter/material.dart';

class CheckpointScreen extends StatelessWidget {
  const CheckpointScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F9),

      appBar: AppBar(
        title: const Text(
          'Master Checkpoint',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Master Checkpoint',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Kelola checkpoint untuk kegiatan patroli.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 24),

            // =========================
            // TOMBOL TAMBAH CHECKPOINT
            // =========================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Form tambah checkpoint
                  // akan kita buat nanti.
                },
                icon: const Icon(
                  Icons.add_location_alt_rounded,
                ),
                label: const Text(
                  'Tambah Checkpoint',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // =========================
            // DAFTAR CHECKPOINT
            // =========================
            Expanded(
              child: ListView(
                children: [
                  _checkpointCard(
                    number: '01',
                    name: 'Checkpoint Pos Security',
                    location: 'Area Security',
                    status: true,
                  ),

                  _checkpointCard(
                    number: '02',
                    name: 'Checkpoint Gudang',
                    location: 'Area Gudang',
                    status: true,
                  ),

                  _checkpointCard(
                    number: '03',
                    name: 'Checkpoint Parkiran',
                    location: 'Area Parkir',
                    status: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // CARD CHECKPOINT
  // =========================
  Widget _checkpointCard({
    required String number,
    required String name,
    required String location,
    required bool status,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          // NOMOR CHECKPOINT
          Container(
            width: 48,
            height: 48,

            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: const Color(0xFF0E7FA8)
                  .withValues(alpha: 0.12),

              borderRadius: BorderRadius.circular(14),
            ),

            child: Text(
              number,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0E7FA8),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // INFORMASI CHECKPOINT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  location,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // STATUS
          Icon(
            status
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,

            color: status
                ? Colors.green
                : Colors.grey,
          ),
        ],
      ),
    );
  }
}