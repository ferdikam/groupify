<?php

namespace App\Filament\Resources\GroupageResource\Pages;

use App\Filament\Resources\GroupageResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListGroupages extends ListRecords
{
    protected static string $resource = GroupageResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
