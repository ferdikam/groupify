<?php

namespace App\Filament\Resources\GroupageResource\Pages;

use App\Filament\Resources\GroupageResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditGroupage extends EditRecord
{
    protected static string $resource = GroupageResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\ViewAction::make(),
            Actions\DeleteAction::make(),
        ];
    }
}
