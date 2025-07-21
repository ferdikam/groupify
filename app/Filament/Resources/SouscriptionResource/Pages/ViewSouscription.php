<?php

namespace App\Filament\Resources\SouscriptionResource\Pages;

use App\Filament\Resources\SouscriptionResource;
use Filament\Actions;
use Filament\Resources\Pages\ViewRecord;

class ViewSouscription extends ViewRecord
{
    protected static string $resource = SouscriptionResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\EditAction::make(),
        ];
    }
}
