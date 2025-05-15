<?php

namespace App\Filament\Resources\ProduitResource\Pages;

use App\Filament\Resources\ProduitResource;
use Filament\Actions;
use Filament\Resources\Pages\ViewRecord;

class ViewProduit extends ViewRecord
{
    protected static string $resource = ProduitResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\EditAction::make(),
        ];
    }
}
