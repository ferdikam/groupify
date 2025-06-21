<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ProduitResource\Pages;
use App\Filament\Resources\ProduitResource\RelationManagers;
use App\Models\Produit;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Infolists;
use Filament\Infolists\Infolist;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class ProduitResource extends Resource
{
    protected static ?string $model = Produit::class;

    protected static ?string $navigationIcon = 'heroicon-o-rectangle-stack';

    protected static ?int $navigationSort = 3;



    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::make('fournisseur_id')
                    ->relationship('fournisseur', 'nom')
                    ->searchable()
                    ->preload()
                    ->required(),
                Forms\Components\TextInput::make('nom')
                    ->required(),
                Forms\Components\Textarea::make('description')
                    ->required()
                    ->columnSpanFull(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('fournisseur.nom')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('nom')
                    ->searchable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('updated_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                //
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            //RelationManagers\GroupagesRelationManager::class,
        ];
    }

   public static function infolist(Infolist $infolist): Infolist
    {
        /*return $infolist->schema([
            Infolists\Components\TextEntry::make('nom')
        ]);*/
        return $infolist
            ->schema([
                Infolists\Components\Section::make('Informations du produit')
                    ->schema([
                        Infolists\Components\Grid::make(2)
                            ->schema([
                                Infolists\Components\TextEntry::make('nom')
                                    ->label('Nom du produit')
                                    ->size(Infolists\Components\TextEntry\TextEntrySize::Large)
                                    ->weight('bold'),

                                Infolists\Components\TextEntry::make('fournisseur.nom')
                                    ->label('Fournisseur')
                                    ->badge()
                                    ->color('info'),
                            ]),

                        Infolists\Components\TextEntry::make('description')
                            ->label('Description')
                            ->columnSpanFull(),
                    ]),

                Infolists\Components\Section::make('Groupages associés')
                    ->schema([
                        Infolists\Components\RepeatableEntry::make('groupages')
                            ->schema([
                                Infolists\Components\Grid::make(4)
                                    ->schema([
                                        Infolists\Components\TextEntry::make('nom')
                                            ->label('Nom du groupage'),

                                        Infolists\Components\TextEntry::make('statut')
                                            ->label('Statut')
                                            ->badge()
                                            ->color(fn (string $state): string => match ($state) {
                                                'brouillon' => 'gray',
                                                'publié' => 'success',
                                                'livré' => 'info',
                                                'archivé' => 'warning',
                                                default => 'gray',
                                            }),

                                        Infolists\Components\TextEntry::make('pivot.prix_vente')
                                            ->label('Prix de vente')
                                            ->formatStateUsing(fn ($state) => number_format($state, 0, ',', ' ') . ' FCFA')
                                            ->color('success')
                                            ->weight('bold'),

                                        Infolists\Components\TextEntry::make('pivot.moq')
                                            ->label('MOQ')
                                            ->formatStateUsing(fn ($state) => number_format($state, 0, ',', ' '))
                                            ->color('warning'),
                                    ])
                            ])
                            ->columns(1)
                            ->visible(fn ($record) => $record->groupages->count() > 0),

                        Infolists\Components\TextEntry::make('groupages_empty')
                            ->label('')
                            ->formatStateUsing(fn () => 'Aucun groupage associé à ce produit.')
                            ->color('gray')
                            ->visible(fn ($record) => $record->groupages->count() === 0),
                    ])
                    ->collapsible(),

                Infolists\Components\Section::make('Souscripteurs par groupage')
                    ->schema([
                        Infolists\Components\Livewire::make(\App\Livewire\ProduitSouscripteurs::class)
                            ->key('produit-souscripteurs')
                            ,
                    ])
                    ->visible(fn ($record) => $record->groupages->count() > 0),

                /*Infolists\Components\Section::make('Statistiques')
                    ->schema([
                        Infolists\Components\Grid::make(3)
                            ->schema([
                                Infolists\Components\TextEntry::make('groupages_count')
                                    ->label('Nombre de groupages')
                                    ->formatStateUsing(fn ($record) => $record->groupages->count())
                                    ->color('info')
                                    ->size(Infolists\Components\TextEntry\TextEntrySize::Large)
                                    ->weight('bold'),

                                Infolists\Components\TextEntry::make('quantite_totale_souscrite')
                                    ->label('Quantité totale souscrite')
                                    ->formatStateUsing(function ($record) {
                                        $total = $record->souscriptions()
                                            ->sum('produit_souscription.quantite');
                                        return number_format($total, 0, ',', ' ');
                                    })
                                    ->color('success')
                                    ->size(Infolists\Components\TextEntry\TextEntrySize::Large)
                                    ->weight('bold'),

                                Infolists\Components\TextEntry::make('nombre_souscripteurs')
                                    ->label('Nombre de souscripteurs')
                                    ->formatStateUsing(function ($record) {
                                        $count = $record->souscriptions()
                                            ->distinct('souscription_id')
                                            ->count();
                                        return $count;
                                    })
                                    ->color('warning')
                                    ->size(Infolists\Components\TextEntry\TextEntrySize::Large)
                                    ->weight('bold'),
                            ])
                    ])
                    ->collapsible(),*/
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListProduits::route('/'),
            'create' => Pages\CreateProduit::route('/create'),
            'view' => Pages\ViewProduit::route('/{record}'),
            'edit' => Pages\EditProduit::route('/{record}/edit'),
        ];
    }
}
