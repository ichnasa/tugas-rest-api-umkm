<?php

namespace App\Models;

use CodeIgniter\Model;

class UmkmModel extends Model
{
    public const KATEGORI = ['Kuliner', 'Fashion', 'Kerajinan', 'Jasa', 'Pertanian', 'Lainnya'];

    protected $table          = 'umkm';
    protected $primaryKey     = 'id';
    protected $returnType     = 'array';
    protected $allowedFields  = ['nama_umkm', 'pemilik', 'alamat', 'kategori', 'kontak'];
    protected $useTimestamps  = true;
    protected $dateFormat     = 'datetime';

    protected $validationRules = [
        'nama_umkm' => 'required|min_length[3]|max_length[150]',
        'pemilik'   => 'required|max_length[100]',
        'alamat'    => 'required',
        'kategori'  => 'required|in_list[Kuliner,Fashion,Kerajinan,Jasa,Pertanian,Lainnya]',
        'kontak'    => 'required|regex_match[/^[0-9+]{8,20}$/]',
    ];

    protected $validationMessages = [
        'nama_umkm' => [
            'required'   => 'Nama UMKM wajib diisi',
            'min_length' => 'Nama UMKM minimal 3 karakter',
            'max_length' => 'Nama UMKM maksimal 150 karakter',
        ],
        'pemilik' => [
            'required'   => 'Pemilik wajib diisi',
            'max_length' => 'Nama pemilik maksimal 100 karakter',
        ],
        'alamat' => [
            'required' => 'Alamat wajib diisi',
        ],
        'kategori' => [
            'required' => 'Kategori wajib diisi',
            'in_list'  => 'Kategori tidak valid',
        ],
        'kontak' => [
            'required'    => 'Kontak wajib diisi',
            'regex_match' => 'Kontak harus berupa nomor telepon (8-20 digit)',
        ],
    ];
}
