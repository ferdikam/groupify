<?php

namespace App\Actions;

use App\Enums\GroupageStatus;
use App\Models\Groupage;

final readonly class CreateGroupageAction
{
    public function __invoke(array $data): Groupage
    {
        return Groupage::create([
            'nom' => $data['nom'],
            'description' => $data['description'] ?? '',
            'date_debut' => $data['date_debut'],
            'date_fin' => $data['date_fin'],
            'statut' => $data['statut'] ?? GroupageStatus::DRAFT,
            'produit_id' => $data['produit_id'],
        ]);
    }
}
