<?php

namespace App\Controllers\Api;

use App\Models\UmkmModel;
use CodeIgniter\HTTP\ResponseInterface;
use CodeIgniter\RESTful\ResourceController;

/**
 * REST API CRUD untuk data UMKM.
 *
 * GET    /api/umkm          -> index()   daftar UMKM (dukung ?page, ?per_page, ?search, ?kategori)
 * GET    /api/umkm/{id}     -> show()    detail UMKM
 * POST   /api/umkm          -> create()  tambah UMKM
 * PUT    /api/umkm/{id}     -> update()  ubah UMKM
 * DELETE /api/umkm/{id}     -> delete()  hapus UMKM
 */
class UmkmController extends ResourceController
{
    protected $modelName = UmkmModel::class;
    protected $format    = 'json';

    /** @var UmkmModel */
    protected $model;

    public function index()
    {
        $page    = max(1, (int) ($this->request->getGet('page') ?? 1));
        $perPage = min(100, max(1, (int) ($this->request->getGet('per_page') ?? 10)));
        $search  = trim((string) $this->request->getGet('search'));
        $kategori = trim((string) $this->request->getGet('kategori'));

        $builder = $this->model->orderBy('id', 'DESC');
        if ($search !== '') {
            $builder->groupStart()
                ->like('nama_umkm', $search)
                ->orLike('pemilik', $search)
                ->orLike('alamat', $search)
                ->groupEnd();
        }
        if ($kategori !== '') {
            $builder->where('kategori', $kategori);
        }

        $data  = $builder->paginate($perPage, 'default', $page);
        $pager = $this->model->pager;

        return $this->success('Data UMKM berhasil diambil', $data, ResponseInterface::HTTP_OK, [
            'page'        => $pager->getCurrentPage(),
            'per_page'    => $pager->getPerPage(),
            'total'       => $pager->getTotal(),
            'total_pages' => $pager->getPageCount(),
        ]);
    }

    public function show($id = null)
    {
        $umkm = $this->model->find($id);
        if ($umkm === null) {
            return $this->notFoundResponse('Gagal mengambil data UMKM', $id);
        }

        return $this->success('Detail UMKM berhasil diambil', $umkm);
    }

    public function create()
    {
        $input = $this->input();

        if (! $this->model->insert($input)) {
            return $this->fail400('Gagal menambahkan data UMKM', $this->model->errors());
        }

        $umkm = $this->model->find($this->model->getInsertID());

        return $this->success('Data UMKM berhasil ditambahkan', $umkm, ResponseInterface::HTTP_CREATED);
    }

    public function update($id = null)
    {
        if ($this->model->find($id) === null) {
            return $this->notFoundResponse('Gagal memperbarui data UMKM', $id);
        }

        $input = $this->input();

        if (! $this->model->update($id, $input)) {
            return $this->fail400('Gagal memperbarui data UMKM', $this->model->errors());
        }

        return $this->success('Data UMKM berhasil diperbarui', $this->model->find($id));
    }

    public function delete($id = null)
    {
        $umkm = $this->model->find($id);
        if ($umkm === null) {
            return $this->notFoundResponse('Gagal menghapus data UMKM', $id);
        }

        $this->model->delete($id);

        return $this->success('Data UMKM berhasil dihapus', [
            'id'        => (int) $umkm['id'],
            'nama_umkm' => $umkm['nama_umkm'],
        ]);
    }

    /**
     * Ambil body request: JSON (application/json) atau form-data / x-www-form-urlencoded.
     */
    private function input(): array
    {
        $json = $this->request->getJSON(true);
        if (is_array($json)) {
            $data = $json;
        } else {
            $data = $this->request->getPost() ?: $this->request->getRawInput();
        }

        $allowed = ['nama_umkm', 'pemilik', 'alamat', 'kategori', 'kontak'];

        return array_intersect_key((array) $data, array_flip($allowed));
    }

    private function success(string $message, $data, int $status = ResponseInterface::HTTP_OK, ?array $meta = null)
    {
        $body = [
            'success' => true,
            'message' => $message,
            'data'    => $this->castData($data),
        ];
        if ($meta !== null) {
            $body['meta'] = $meta;
        }

        return $this->respond($body, $status);
    }

    private function fail400(string $message, array $errors)
    {
        return $this->respond([
            'success' => false,
            'message' => $message,
            'errors'  => $errors,
        ], ResponseInterface::HTTP_BAD_REQUEST);
    }

    private function notFoundResponse(string $message, $id)
    {
        return $this->respond([
            'success' => false,
            'message' => $message,
            'errors'  => ['id' => "UMKM dengan id {$id} tidak ditemukan"],
        ], ResponseInterface::HTTP_NOT_FOUND);
    }

    /** Pastikan `id` dikirim sebagai integer (SQLite/MySQL bisa mengembalikan string). */
    private function castData($data)
    {
        if (is_array($data) && array_is_list($data)) {
            return array_map(fn ($row) => $this->castData($row), $data);
        }
        if (is_array($data) && isset($data['id'])) {
            $data['id'] = (int) $data['id'];
        }

        return $data;
    }
}
