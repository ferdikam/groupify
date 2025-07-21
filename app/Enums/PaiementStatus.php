<?php

namespace App\Enums;

use Filament\Support\Contracts\HasDescription;
use Filament\Support\Contracts\HasLabel;

enum PaiementStatus: string implements HasLabel, HasDescription
{
    case PENDING = 'en attente' ;
    case PARTIALLY = 'paiement partiel' ;
    case FULLY = 'paiement intégral' ;
    case REFUNDED = 'rembourse' ;

    public function color(): string
    {
        return match ($this) {
            PaiementStatus::PENDING => 'bg-gray-400',
            PaiementStatus::PARTIALLY => 'bg-green-400',
            PaiementStatus::FULLY => 'bg-blue-400',
            PaiementStatus::REFUNDED => 'bg-yellow-400',
        };


    }

    public function getDescription(): ?string
    {
        return match ($this) {
            self::PENDING => 'En attente de paiement.',
            self::PARTIALLY => 'Paiement partiel.',
            self::FULLY => 'Paiement intégral.',
            self::REFUNDED => 'A staff member has decided this is not appropriate for the website.',
        };
    }

    public function getLabel(): ?string
    {
        return match ($this) {
            self::PENDING => 'en attente',
            self::PARTIALLY => 'paiement partiel',
            self::FULLY => 'paiement intégral',
            self::REFUNDED => 'rembourse',
        };
    }
}
