@foreach($groupages as $groupage)
    <h2>{{ $groupage->nom }}</h2>
    <p>{{ $groupage->date_debut }}</p>
    <p>{{ $groupage->date_fin}}</p>
    <p>{{ $groupage->statut}}</p>
@endforeach