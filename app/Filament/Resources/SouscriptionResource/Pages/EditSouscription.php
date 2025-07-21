<?php

namespace App\Filament\Resources\SouscriptionResource\Pages;

use App\Filament\Resources\SouscriptionResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditSouscription extends EditRecord
{
    protected static string $resource = SouscriptionResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\ViewAction::make(),
            Actions\DeleteAction::make(),
        ];
    }
}
