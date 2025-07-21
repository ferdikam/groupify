<?php

namespace App\Livewire;

use App\Models\Groupage;
use App\Models\Produit;
use Illuminate\Database\Eloquent\Model;
use Livewire\Component;

class ProduitSouscripteurs extends Component
{
    public Produit $produit;
    public ?int $groupageSelectionne = null;
    public $souscripteurs = [];

    public function mount(Produit $record)
    {
        $this->produit = $record;

        // Sélectionner automatiquement le premier groupage s'il existe
        $premierGroupage = $this->produit->groupages()->first();
        if ($premierGroupage) {
            $this->groupageSelectionne = $premierGroupage->id;
            $this->chargerSouscripteurs();
        }
    }

    public function updatedGroupageSelectionne(): void
    {
        $this->chargerSouscripteurs();
    }

    public function chargerSouscripteurs(): void
    {
        if (!$this->groupageSelectionne) {
            $this->souscripteurs = [];
            return;
        }

        $groupage = Groupage::find($this->groupageSelectionne);

        if (!$groupage) {
            $this->souscripteurs = [];
            return;
        }

        // Récupérer toutes les souscriptions pour ce groupage qui contiennent ce produit
        $this->souscripteurs = $groupage->souscriptions()
            ->with(['client', 'produits' => function($query) {
                $query->where('produit_id', $this->produit->id);
            }])
            ->whereHas('produits', function($query) {
                $query->where('produit_id', $this->produit->id);
            })
            ->get()
            ->map(function($souscription) {
                $produitSouscription = $souscription->produits->first();

                return [
                    'souscription_id' => $souscription->id,
                    'numero_souscription' => $souscription->numero_souscription,
                    'client_nom' => $souscription->client->nom,
                    'client_prenoms' => $souscription->client->prenoms,
                    'client_telephone' => $souscription->client->telephone,
                    'quantite' => $produitSouscription ? $produitSouscription->pivot->quantite : 0,
                    'prix_unitaire' => $produitSouscription ? $produitSouscription->pivot->prix_unitaire : 0,
                    'sous_total' => $produitSouscription ? $produitSouscription->pivot->sous_total : 0,
                    'statut_souscription' => $souscription->statut,
                    'date_souscription' => $souscription->date_souscription,
                ];
            })
            ->sortBy(['client_nom', 'client_prenoms']);
    }

    public function getTotalQuantiteProperty()
    {
        return collect($this->souscripteurs)->sum('quantite');
    }


    public function getTotalMontantProperty()
    {
        return collect($this->souscripteurs)->sum('sous_total');
    }

    public function getNombreSouscripteursProperty()
    {
        return count($this->souscripteurs);
    }

    public function getMoqProperty()
    {
        if (!$this->groupageSelectionne) {
            return 0;
        }

        $groupage = Groupage::find($this->groupageSelectionne);
        if (!$groupage) {
            return 0;
        }

        $pivot = $this->produit->groupages()
            ->where('groupage_id', $this->groupageSelectionne)
            ->first()?->pivot;

        return $pivot ? $pivot->moq : 0;
    }

    public function getQuantiteRestanteCommandeeProperty()
    {
        $moq = $this->moq;
        $totalQuantite = $this->totalQuantite;

        $quantiteRestante = $moq - $totalQuantite;

        // Retourner 0 si négatif (objectif déjà atteint)
        return max(0, $quantiteRestante);
    }

    public function getPourcentageObjectifProperty()
    {
        $moq = $this->moq;
        if ($moq == 0) {
            return 0;
        }

        $totalQuantite = $this->totalQuantite;
        return min(100, round(($totalQuantite / $moq) * 100, 1));
    }

    public function getObjectifAtteintProperty()
    {
        return $this->totalQuantite >= $this->moq;
    }

    public function exporterCSV()
    {
        if (!$this->groupageSelectionne || empty($this->souscripteurs)) {
            session()->flash('error', 'Aucune donnée à exporter.');
            return;
        }

        $groupage = Groupage::find($this->groupageSelectionne);
        $filename = "souscripteurs_{$this->produit->nom}_{$groupage->nom}_" . date('Y-m-d') . ".csv";

        $headers = [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
        ];

        $csv = "Client,Téléphone,N° Souscription,Quantité,Prix unitaire,Sous-total,Statut,Date\n";

        foreach ($this->souscripteurs as $souscripteur) {
            $csv .= sprintf(
                "\"%s %s\",\"%s\",\"%s\",%d,%d,%d,\"%s\",\"%s\"\n",
                $souscripteur['client_nom'],
                $souscripteur['client_prenoms'],
                $souscripteur['client_telephone'],
                $souscripteur['numero_souscription'],
                $souscripteur['quantite'],
                $souscripteur['prix_unitaire'],
                $souscripteur['sous_total'],
                ucfirst(str_replace('_', ' ', $souscripteur['statut_souscription'])),
                \Carbon\Carbon::parse($souscripteur['date_souscription'])->format('d/m/Y')
            );
        }

        return response()->streamDownload(function() use ($csv) {
            echo $csv;
        }, $filename, $headers);
    }

    public function rafraichir()
    {
        $this->chargerSouscripteurs();
        session()->flash('success', 'Données actualisées avec succès.');
    }

    public function render()
    {
        // Debug : vérifier si le produit existe
        if (!$this->produit) {
            logger('Erreur: Produit non trouvé dans ProduitSouscripteurs');
            return view('livewire.produit-souscripteurs', ['groupages' => collect()]);
        }

        // Charger les groupages avec debug
        $groupages = $this->produit->groupages()
            ->select('groupages.id', 'groupages.nom', 'groupages.statut')
            ->orderBy('nom')
            ->get();

        // Debug : logger le nombre de groupages trouvés
        logger("Produit ID {$this->produit->id} - Groupages trouvés: " . $groupages->count());

        return view('livewire.produit-souscripteurs', [
            'groupages' => $groupages,
        ]);
    }

    // Méthode pour tester la relation (peut être appelée depuis Tinker)
    public function testRelation()
    {
        $this->info("=== TEST DE RELATION ===");
        $this->info("Produit: {$this->produit->nom}");
        $this->info("ID: {$this->produit->id}");

        $groupages = $this->produit->groupages;
        $this->info("Nombre de groupages: " . $groupages->count());

        foreach ($groupages as $groupage) {
            $this->info("- {$groupage->nom} (ID: {$groupage->id})");
        }

        return $groupages;
    }
}
