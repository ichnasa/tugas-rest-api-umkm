<?php

namespace App\Database\Seeds;

use CodeIgniter\Database\Seeder;

class UmkmSeeder extends Seeder
{
    public function run()
    {
        $now  = date('Y-m-d H:i:s');
        $data = [
            ['Kopi Nusantara', 'Rafi A', 'Jl. A. Yani No. 10, Banjarbaru', 'Kuliner', '081234560001'],
            ['Sasirangan Banua', 'Siti Aminah', 'Jl. Pangeran Antasari No. 5, Banjarmasin', 'Fashion', '081234560002'],
            ['Kerajinan Purun Lestari', 'H. Ahmad', 'Desa Purun, Kab. Banjar', 'Kerajinan', '081234560003'],
            ['Amplang Pak Udin', 'Udin Saputra', 'Jl. Sultan Adam No. 21, Banjarmasin', 'Kuliner', '081234560004'],
            ['Servis HP Cepat', 'Budi Santoso', 'Jl. Panglima Batur No. 3, Banjarbaru', 'Jasa', '081234560005'],
        ];

        foreach ($data as [$nama, $pemilik, $alamat, $kategori, $kontak]) {
            $this->db->table('umkm')->insert([
                'nama_umkm'  => $nama,
                'pemilik'    => $pemilik,
                'alamat'     => $alamat,
                'kategori'   => $kategori,
                'kontak'     => $kontak,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }
    }
}
