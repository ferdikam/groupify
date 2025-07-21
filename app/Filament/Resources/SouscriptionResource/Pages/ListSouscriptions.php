<?php

namespace App\Filament\Resources\SouscriptionResource\Pages;

use App\Filament\Resources\SouscriptionResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListSouscriptions extends ListRecords
{
    protected static string $resource = SouscriptionResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
