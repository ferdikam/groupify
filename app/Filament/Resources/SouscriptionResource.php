<?php

namespace App\Filament\Resources;

use App\Filament\Resources\SouscriptionResource\Pages;
use App\Filament\Resources\SouscriptionResource\RelationManagers;
use App\Models\Groupage;
use App\Models\Produit;
use App\Models\Souscription;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Forms\Get;
use Filament\Forms\Set;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class SouscriptionResource extends Resource
{
    protected static ?string $model = Souscription::class;

    protected static ?string $navigationIcon = 'heroicon-o-rectangle-stack';

    protected static ?string $navigationGroup = 'Gestion Souscriptions';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make("Informations de base")
                    ->schema([
                        Forms\Components\Select::make('client_id')
                            ->relationship('client', 'id')
                            ->getOptionLabelFromRecordUsing(fn ($record) => "{$record->nom} {$record->prenoms}")
                            ->searchable(['nom', 'prenoms', 'telephone'])
                            ->preload()
                            ->required(),

                        Forms\Components\Select::make('groupage_id')
                            ->relationship('groupage', 'nom')
                            ->searchable()
                            ->preload()
                            ->required()
                            ->live()
                            ->afterStateUpdated(fn (Set $set) => $set('produits', [])),

                        Forms\Components\TextInput::make('numero_souscription')
                            ->label('Numéro de souscription')
                            ->default(fn () => Souscription::genererNumeroSouscription())
                            ->required()
                            ->unique(ignoreRecord: true)
                            ->maxLength(255),

                        Forms\Components\Select::make('statut')
                            ->options([
                                'en_attente' => 'En attente',
                                'confirmee' => 'Confirmée',
                                'payee' => 'Payée',
                                'annulee' => 'Annulée',
                            ])
                            ->default('en_attente')
                            ->required(),

                        Forms\Components\DatePicker::make('date_souscription')
                            ->default(now())
                            ->required(),
                    ])->columns(2),


                Forms\Components\Section::make('Produits souscrits')
                    ->schema([
                        Forms\Components\Repeater::make('souscriptionProduits')
                            ->relationship('souscriptionProduits') // Utiliser la relation HasMany
                            ->schema([
                                Forms\Components\Select::make('produit_id')
                                    ->label('Produit')
                                    ->options(function (Get $get) {
                                        $groupageId = $get('../../groupage_id');
                                        if (!$groupageId) return [];

                                        return Groupage::find($groupageId)
                                            ->produits()
                                            ->select('produits.id', 'produits.nom')
                                            ->pluck('nom', 'id');
                                    })
                                    ->required()
                                    ->live()
                                    ->afterStateUpdated(function (Set $set, Get $get, $state) {
                                        if (!$state) return;

                                        $groupageId = $get('../../groupage_id');
                                        $produit = Produit::find($state);

                                        if ($produit && $groupageId) {
                                            $prixVente = $produit->getPrixVentePourGroupage($groupageId);
                                            $set('prix_unitaire', $prixVente);

                                            $quantite = $get('quantite') ?: 1;
                                            $set('sous_total', $quantite * $prixVente);
                                        }
                                    }),

                                Forms\Components\TextInput::make('quantite')
                                    ->label('Quantité')
                                    ->numeric()
                                    ->minValue(1)
                                    ->default(1)
                                    ->required()
                                    ->live()
                                    ->afterStateUpdated(function (Set $set, Get $get, $state) {
                                        $prixUnitaire = $get('prix_unitaire') ?: 0;
                                        $set('sous_total', $state * $prixUnitaire);
                                    }),

                                Forms\Components\TextInput::make('prix_unitaire')
                                    ->label('Prix unitaire (FCFA)')
                                    ->numeric()
                                    ->required()
                                    ->live()
                                    ->afterStateUpdated(function (Set $set, Get $get, $state) {
                                        $quantite = $get('quantite') ?: 1;
                                        $set('sous_total', $quantite * $state);
                                    }),

                                Forms\Components\TextInput::make('sous_total')
                                    ->label('Sous-total (FCFA)')
                                    ->numeric()
                                    ->disabled()
                                    ->dehydrated(),
                            ])
                            ->columns(4)
                            ->addActionLabel('Ajouter un produit')
                            ->collapsible()
                            ->itemLabel(function (array $state): ?string {
                                if (!isset($state['produit_id'])) return null;
                                $produit = Produit::find($state['produit_id']);
                                return $produit?->nom . " (Qté: {$state['quantite']})";
                            }),
                    ]),


                Forms\Components\Section::make('Montants')
                    ->schema([
                        Forms\Components\Placeholder::make('montant_total_display')
                            ->label('Montant total')
                            ->content(function (Get $get): string {
                                $produits = $get('souscriptionProduits') ?: []; // Changé de 'produits' à 'souscriptionProduits'
                                $total = collect($produits)->sum('sous_total');
                                return number_format($total, 0, ',', ' ') . ' FCFA';
                            }),

                        Forms\Components\TextInput::make('montant_paye')
                            ->label('Montant payé (FCFA)')
                            ->numeric()
                            ->default(0)
                            ->minValue(0),
                    ])->columns(2),

               /* Forms\Components\Section::make('Montants')
                    ->schema([
                        Forms\Components\Placeholder::make('montant_total_display')
                            ->label('Montant total')
                            ->content(function (Get $get): string {
                                $produits = $get('produits') ?: [];
                                $total = collect($produits)->sum('sous_total');
                                return number_format($total, 0, ',', ' ') . ' FCFA';
                            }),

                        Forms\Components\TextInput::make('montant_paye')
                            ->label('Montant payé (FCFA)')
                            ->numeric()
                            ->default(0)
                            ->minValue(0),
                    ])->columns(2),*/

            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('client.nom_complet')
                    ->sortable(),
                Tables\Columns\TextColumn::make('groupage.nom')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('numero_souscription')
                    ->searchable(),
                Tables\Columns\TextColumn::make('montant_paye')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('statut')
                    ->searchable(),
                Tables\Columns\TextColumn::make('date_souscription')
                    ->date()
                    ->sortable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('updated_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->defaultGroup('groupage.nom')
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
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListSouscriptions::route('/'),
            'create' => Pages\CreateSouscription::route('/create'),
            'view' => Pages\ViewSouscription::route('/{record}'),
            'edit' => Pages\EditSouscription::route('/{record}/edit'),
        ];
    }
}
